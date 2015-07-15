package OpenAir::Types;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

enum 'OpenAir::MetaStatus', ['LOG', 'TODO', 'ISSUE', 'NOTE', 'DESC'];

enum 'OpenAir::AltitudeType', ['STD', 'MSL', 'AGL'];

enum 'OpenAir::AltitudeFlag', ['UNLIM', 'SFC'];

subtype 'OpenAir::PositiveNum',
    as 'Num',
    where { $_ >= 0 };

subtype 'OpenAir::PositiveInt',
    as 'Int',
    where { $_ >= 0 };

enum 'OpenAir::DegreeSign', [qw (+ -)];

subtype 'OpenAir::Latitude',
    as 'OpenAir::Degree',
    where { $_->totalSecs <= 90 * 60 * 60 },
    message { "Latitude can't be more than 90 degrees" };

subtype 'OpenAir::Longitude',
    as 'OpenAir::Degree',
    where { $_->totalSecs <= 180 * 60 * 60 },
    message { "Longitude can't be more than 180 degrees" };

subtype 'OpenAir::Angle',
    as 'Num',
    where { $_ >= 0 && $_ < 360 };

enum 'OpenAir::VarsDir', ['CW', 'CCW'];

__PACKAGE__->meta->make_immutable;
