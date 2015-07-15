package OpenAir::Airway;

use namespace::autoclean;
use Moose;

extends 'OpenAir::Element';

has 'point' => (
    is => 'rw',
    isa => 'OpenAir::Point',
    required => 1
    );

__PACKAGE__->meta->make_immutable;
