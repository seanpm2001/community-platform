package DDGC::DB::Result::Comment;

use Moose;
use MooseX::NonMoose;
extends 'DDGC::DB::Base::Result';
use DBIx::Class::Candy;
use namespace::autoclean;

table 'comment';

sub u { 
	my ( $self ) = @_;
	if ( my $context_obj = $self->get_context_obj ) {
		if ($context_obj->can('u_comments')) {
			my $u = $context_obj->u_comments;
			return $u if $u;
		}
		if ($context_obj->can('u')) {
			my $u = $context_obj->u;
			return $u if $u;
		}
	}
	return;
}

column id => {
	data_type => 'bigint',
	is_auto_increment => 1,
};
primary_key 'id';

column users_id => {
	data_type => 'bigint',
	is_nullable => 1,
};

###########
column context => {
	data_type => 'text',
	is_nullable => 0,
};
column context_id => {
	data_type => 'bigint',
	is_nullable => 0,
};
with 'DDGC::DB::Role::HasContext';
###########

column content => {
	data_type => 'text',
	is_nullable => 0,
};

column created => {
	data_type => 'timestamp with time zone',
	set_on_create => 1,
};

column updated => {
	data_type => 'timestamp with time zone',
	set_on_create => 1,
	set_on_update => 1,
};

column parent_id => {
	data_type => 'bigint',
	is_nullable => 1,
};

belongs_to 'user', 'DDGC::DB::Result::User', 'users_id', { join_type => 'left' };
belongs_to 'parent', 'DDGC::DB::Result::Comment', 'parent_id', { join_type => 'left' };
has_many 'children', 'DDGC::DB::Result::Comment', 'parent_id';

after insert => sub {
	my ( $self ) = @_;
	$self->add_event('insert');
};

after update => sub {
	my ( $self ) = @_;
	$self->add_event('update');
};

sub event_related {
	my ( $self ) = @_;
	my @related;
	if ( $self->parent_id ) {
		push @related, [(ref $self), $self->parent_id];
	}
	if ( $self->context_resultset ) {
		push @related, [$self->context, $self->context_id];
		push @related, [$self->get_context_obj->event_related] if $self->get_context_obj->can('event_related');
	}
	return @related;
}

###############################

no Moose;
__PACKAGE__->meta->make_immutable;

1;
