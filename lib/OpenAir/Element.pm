package OpenAir::Element;

use namespace::autoclean;
use Moose;

has 'vars' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::Vars]',
    trigger => \&_varsSet,
    clearer => 'clearVars',
    default => undef
    );

sub _varsSet {
    my $self = shift;
    my $new = shift;
    my $old = shift;
    
    return if defined $old && $new eq $old;

    if (defined $old) {
	$old->unref ();
    }
    $new->ref ();
}

__PACKAGE__->meta->make_immutable;
