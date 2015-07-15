package OpenAir::Vars;

use namespace::autoclean;
use Moose;

with qw(MooseX::Clone);

use OpenAir::Point;

has 'dir' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::VarsDir]',
    clearer => 'clearDir',
    default => undef
    );

has 'center' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::Point]',
    clearer => 'clearCenter',
    default => undef
    );

has 'airwayWidth' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::PositiveNum]',
    clearer => 'clearAirwayWidth',
    default => undef
    );

has 'zoom' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::PositiveNum]',
    clearer => 'clearZoom',
    default => undef
    );

has 'refs' => (
    is => 'rw',
    isa => 'OpenAir::PositiveInt',
    default => 0
    );

sub ref {
    my $self = shift;

    $self->refs ($self->refs + 1);
}

sub unref {
    my $self = shift;

    $self->refs ($self->refs - 1);
}

sub copy {
    my $self = shift;

    return $self->clone (refs => 0);
}

__PACKAGE__->meta->make_immutable;
