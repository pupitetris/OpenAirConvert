package OpenAir::Degree;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

subtype 'PositiveNum',
    as 'Num',
    where { $_ >= 0 };

enum 'DegreeSign', [qw (+ -)];

has 'sign' => (
    is => 'rw',
    isa => 'DegreeSign',
    default => '+'
    );

has 'deg' => (
    is => 'rw',
    isa => 'PositiveNum',
    default => 0
    );

has 'min' => (
    is => 'rw',
    isa => 'PositiveNum',
    default => 0
    );

has 'sec' => (
    is => 'rw',
    isa => 'PositiveNum',
    default => 0
    );

sub totalSecs {
    my $self = shift;

    return $self->sec + ($self->min + $self->deg * 60) * 60;
}

sub eq {
    my $self = shift;
    my $other = shift;

    if (defined $other && 
	$self->totalSecs () == $other->totalSecs () &&
	$self->sign eq $other->sign) {
	return 1;
    }
    return 0;
}

__PACKAGE__->meta->make_immutable;
