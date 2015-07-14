package OpenAir;

# OpenAir file format documentation:
# http://www.winpilot.com/UsersGuide/UserAirspace.asp
#
# File metadata extensions: 
# FMT (File format)
# VER (File version <YYYY-MM-DD>)
# DESC: START, DESC: END (General file description),
# AUTHOR (One per author <handle email name...>)
# TODO (File notes <(handle) notes...>)
# ISSUE (Bugs <(handle) issue...>)
# LOG (<(handle) YYYY-MM-DD Changelog...>)
#
# Polygon grouping metadata: 
# DAT (Chart source issuing date)
# POP (Closest Relevant Population <city, state>)
# APT (Airport name <ICAO name>)
# APT: END marks end of airport grouping.
# NOTE (Notes for airport or polygon <(handle) text...>)

use Switch;
use Carp ();
use String::Strip;

use namespace::autoclean;
use Moose;
use MooseX::ClassAttribute;
use Moose::Util::TypeConstraints;

use OpenAir::Altitude;
use OpenAir::Point;
use OpenAir::Degree;

%OpenAir::CLASS_TYPES = (
    R => 'Restricted',
    Q => 'Danger',
    P => 'Prohibited',
    A => 'Class A (IFR-only)',
    B => 'Class B',
    C => 'Class C',
    D => 'Class D (TMA)',
    E => 'Class E (Airways)',
    F => 'Class F',
    G => 'Class G',
    GP => 'Glider Prohibited',
    CTR => 'Controlled',
    W => 'Wave Window',
    TMZ => 'Transponder Mandatory Zone',
    RMZ => 'Radio Mandatory Zone',
    MATZ => 'Military Air Traffic Zone'
    );

%OpenAir::CLASS_SYNONYMS = (
    CTA => 'CTR',
    'CTA/CTR' => 'CTR',
    'CTR/CTA' => 'CTR',
    RESTRICTED => 'R',
    DANGER => 'Q',
    PROHIBITED => 'P',
    GSEC => 'W',
    T => 'TMZ',
    CYR => 'R',
    CYD => 'Q',
    CYA => 'F',
    );

%OpenAir::DRAWCMD_TYPENAMES => (
    DP => 'POINT',
    DA => 'ARC',
    DB => 'ARC3P',
    DC => 'CIRCLE',
    DY => 'AIRWAY'
    );

class_has CLASS_TYPES => (
    is => 'ro',
    isa => 'HashRef[Str]',
    default => sub { \%OpenAir::CLASS_TYPES }
    );

has _status => (
    is => 'ro', 
    isa => 'HashRef',
    default => sub { {
	AUTHOR => {},
	APT => {},
	POP => { UNK => { APT => {} } },
	STATE => {},
	AIRSPACE => [],
	VAR => { _refs => 0 },
	} 
    },
    init_arg => undef
    );

has _lineStr => (
    is => 'rw',
    isa => 'Str',
    init_arg => undef
    );

has lineNum => (
    is => 'rw',
    isa => 'Num',
    default => 0,
    init_arg => undef
    );

has classes => (
    is => 'ro',
    isa => 'HashRef[ArrayRef]',
    default => sub {
	my %val = ();
	foreach my $i (keys %OpenAir::CLASS_TYPES) {
	    $val {$i} = [];
	}
	return \%val;
    },
    init_arg => undef
    );

enum 'MetaStatus', ['LOG', 'TODO', 'ISSUE', 'NOTE', 'DESC'];

has _metaStatus => (
    is => 'rw',
    isa => 'Maybe[MetaStatus]',
    init_arg => undef,
    clearer => '_clearMetaStatus',
    predicate => '_hasMetaStatus'
    );

sub _msgFmt {
    my $self = shift;
    my $msg = shift;

    return $msg . "\n" . $self->lineNum . ': «' . $self->_lineStr . "»\n";
}

sub carp {
    my $self = shift;
    my $msg = shift;

    Carp::carp ($self->_msgFmt ($msg));
}

sub croak {
    my $self = shift;
    my $msg = shift;

    Carp::croak ($self->_msgFmt ($msg));
}

sub _parseNum {
    my $self = shift;
    my $val = shift;

    if ($val =~ /^[0-9]+(\.[0-9]+)?|^\.[0-9]+$/) {
	return $val;
    }
    $self->carp ('Expected positive numeric value');
    return undef;
}

sub _parseInt {
    my $self = shift;
    my $val = shift;

    if ($val =~ /^[0-9]+$/) {
	return $val;
    }
    $self->carp ('Expected positive integer value');
    return undef;
}

sub _parseAlt {
    my $self = shift;
    my $str = uc (shift);

    # Heuristics courtesy of XCSoar.
    my %parms = (unit => 'FT', type => 'MSL', value => 0);

    StripSpace ($str);
    my @chars = split ('', $str);
    while (my $c = shift @chars) {

	if ($c =~ /[\d.]/) {
	    my $num = '';
	    do {
		$num .= $c;
		$c = shift @chars;
	    } while (defined $c && $c =~ /[\d.]/);
	    $parms{value} = $self->_parseNum ($num);
	    last if !defined $c;
	}

	my $found;
	if (scalar @chars < 2) {
	    $found = 0;
	} else {
	    $found = 1;
	    switch (join ('', $c, @chars[0..1])) {
		case 'GND' { next; }
		case 'AGL' { $parms{type} = 'AGL'; }
		case 'SFC' { $parms{flag} = 'SFC'; }
		case 'ALT' { next; }
		case 'MSL' { $parms{type} = 'MSL'; }
		case 'STD' { $parms{type} = 'STD'; }
		case 'UNL' {
		    if (scalar @chars > 4 && $chars[2] eq 'I' && $chars[3] eq 'M') {
			# It says UNLIM, remove two additional chars.
			splice (@chars, 0, 2);
		    }
		    $parms{flag} = 'UNLIM'; 
		}
		else { $found = 0; }
	    }
	}
	if ($found) {
	    splice (@chars, 0, 2);
	} else {
	    if (scalar @chars > 0 && $c . $chars[0] eq 'FL') {
		$parms{type} = 'FL';
		shift @chars;
	    } elsif ($c eq 'F') {
		$parms{unit} = 'FT';
		shift @chars if $chars[0] eq 'T';
	    } elsif ($c eq 'M') {
		$parms{unit} = 'M';
	    }
	}
    }

    if ($parms{type} eq 'FL') {
	$parms{type} = 'STD';
	$parms{value} *= 100;
    }

    return OpenAir::Altitude->new (%parms);
}

sub _parseAngle {
    my $self = shift;
    my $val = shift;

    if (defined $self->_parseNum ($val) &&
	$val >= 0 &&
	$val < 360) {
	return $val;
    }
    $self->carp ('Angle out of bounds 0 <= A < 360');
    return undef;
}

sub _parseCoord {
    my $self = shift;
    my $val = shift;

    if ($val =~ /([0-9]+):([0-9]+(\.[0-9]+)?)(:([0-9]+(\.[0-9]+)?))? ?([NS]) ?([0-9]+):([0-9]+(\.[0-9]+)?)(:([0-9]+(\.[0-9]+)?))? ?([EW])/) {
	my $coord = OpenAir::Point->new (
	    lat => OpenAir::Degree->new (
		sign => ($7 eq 'S')? '-': '+',
		deg => $1,
		min => $2,
		sec => $5 ),
	    lon => OpenAir::Degree->new (
		sign => ($14 eq 'E')? '-': '+',
		deg => $8,
		min => $9,
		sec => $12 ));
	return $coord;
    }
    $self->carp ('Bad coordinate format ' . $val);
    return undef;
}

sub _parsePoint {
    my $self = shift;
    my $args = shift;

    return { COORD => $self->_parseCoord ($args) };
}

sub _parseArc {
    my $self = shift;
    my $args = shift;

    my @args = split (/ ?, ?/, $args, 3);
    if (! defined $args[1] || !defined $args[2]) {
	$self->carp ('Missing parameters for Arc');
	return undef;
    }

    return {
	RADIUS => $self->_parseNum ($args[0]),
	ANG_START => $self->_parseAngle ($args[1]),
	ANG_END => $self->_parseAngle ($args[2])
    };
}

sub _parseArcByCoord {
    my $self = shift;
    my $args = shift;

    my @args = split (/ ?, ?/, $args, 2);
    if (! defined $args[1]) {
	$self->carp ('Missing parameters for Arc');
	return undef;
    }

    return {
	COORD1 => $self->_parseCoord ($args[0]),
	COORD2 => $self->_parseCoord ($args[1])
    };
}

sub _parseCircle {
    my $self = shift;
    my $args = shift;

    return { RADIUS => $self->_parseNum ($args) };
}

sub _parseAirway {
    my $self = shift;
    my $args = shift;

    return { COORD => $self->_parseCoord ($args) };
}

sub _parseDraw {
    my $self = shift;
    my $cmd = shift;
    my $args = shift;

    my $ele;
    switch ($cmd) {
	case 'DP' { $ele = $self->_parsePoint ($args); }
	case 'DA' { $ele = $self->_parseArc ($args); }
	case 'DB' { $ele = $self->_parseArcByCoord ($args); }
	case 'DC' { $ele = $self->_parseCircle ($args); }
	case 'DY' { $ele = $self->_parseAirway ($args); }
	else {
	    $self->carp ('Unrecognized draw command');
	}
    }

    if ($ele) {
	$ele->{TYPE} = $OpenAir::DRAWCMD_TYPENAMES{$cmd};
	$ele->{VAR} = $self->_status->{VAR};
	$self->_status->{VAR}{_refs} ++;
	push $self->_status->{AIRSPACE_CURR}{ELE}, $ele;
    }
}

sub _cloneVars {
    my $self = shift;

    my $vars = $self->_status->{VAR};

    my $new = {};
    foreach my $k (keys %$vars) {
	$new->{$k} = $vars->{$k};
    }
    
    # Reset refs.
    $new->{_refs} = 0;

    return $new;
}

sub _parseVar {
    my $self = shift;
    my $args = shift;

    my ($var, $val);
    if ($args =~ /^([^ =]+) ?= ?(.*)/) {
	$var = $1;
	$val = $2;
    } else {
	$self->carp ('Malformed variable assignment');
	return;
    }

    my $k;
    my $v;

    switch ($var) {
	case 'D' {
	    $k = 'DIR';
	    if ($val eq '+') {
		$v = 'CW';
	    } elsif ($val eq '-') {
		$v = 'CCW';
	    } else {
		$self->carp ('Unrecognized direction value');
	    }
	}
	case 'X' {
	    $k = 'CENTER';
	    $v = $self->_parseCoord ($val);
	}
	case 'W' {
	    $k = 'AW_WIDTH';
	    $v = $self->_parseNum ($val);
	}
	case 'Z' {
	    $k = 'ZOOM'; 
	    $v = $self->_parseNum ($val);
	}
	else {
	    $self->carp ('Unrecognized variable name');
	}
    }

    return if (! defined $k || ! defined $v);

    my $vars = $self->_status->{VAR};

    # If value assigned is equal to the old one, do nothing.
    if ($k eq 'CENTER') {
	if ($v->eq ($vars->{'CENTER'})) {
	    return;
	}
    } else {
	if (defined $vars->{$k} && $v eq $vars->{$k}) {
	    return;
	}
    }

    # If the vars context has already been used by an element, clone.
    if ($vars->{_refs} > 0) {
	my $new = $self->_cloneVars ();

	# Assign parsed value to corresponding key.
	$new->{$k} = $v;

	# Use cloned context as current one.
	$self->_status->{VAR} = $new;
    }
}

sub _parseCommand {
    my $self = shift;
    my $line = shift;

    my ($cmd, $args) = split (/ /, $line, 2);
    if ($cmd ne 'TO' && $cmd ne 'TC' && $args eq '') {
	$self->carp ('Missing required argument');
	return;
    }

    switch ($cmd) {
	case 'AC' {
	    my $class = uc ($args);
	    if (!exists OpenAir->CLASS_TYPES->{$class}) {
		my $syn = $OpenAir::CLASS_SYNONYMS{$class};
		if ($syn) {
		    $class = $syn;
		} else {
		    $self->carp ('Unrecognized airspace class ' . $args);
		}
	    }

	    my $air = { 
		CLASS => $class,
		ELE => []
	    };
	    push $self->_status->{AIRSPACE}, $air;
	    $self->_status->{AIRSPACE_CURR} = $air;
	}
	case 'AN' {
	    $self->_status->{AIRSPACE_CURR}{NAME} = $args;
	}
	case 'AT' {
	    if (my $coord = $self->_parseCoord ($args)) {
		my $arr = $self->_status->{AIRSPACE_CURR}{TEXT_COORD};
		if (!$arr) {
		    $arr = [];
		    $self->_status->{AIRSPACE_CURR}{TEXT_COORD} = $arr;
		}
		push $arr, $coord;
	    }
	}
	case 'AH' { $self->_status->{AIRSPACE_CURR}{AIRHIGH} = $self->_parseAlt ($args); }
	case 'AL' { $self->_status->{AIRSPACE_CURR}{AIRLOW} = $self->_parseAlt ($args); }
	case 'V'  { $self->_parseVar ($args); }
	case /^D/ { $self->_parseDraw ($cmd, $args); }
	case 'TO' { next; }
	case 'TC' { next; }
	case 'SP' { next; }
	case 'SB' { $self->carp ('Command not implemented yet'); }
	else      { $self->carp ('Unrecognized command'); }
    }
}

sub _parseMetaDesc {
    my $self = shift;
    my $cmd = shift;
    my $args = shift;

    if ($cmd eq 'DESC') {
	if ($args eq 'END') {
	    if ($self->_metaStatus eq 'DESC') {
		$self->_clearMetaStatus ();
		return 1;
	    } else {
		$self->croak ('DESC: END found without corresponding DESC: START');
	    }
	} elsif ($args eq 'START') {
	    if ($self->_hasMetaStatus ()) {
		$self->croak ('DESC: START found within DESC: START');
	    }
	    $self->_metaStatus ('DESC');
	    return 1;
	}
    }
}

sub _parseMetaSingleEntry {
    my $self = shift;
    my $cmd = shift;
    my $args = shift;

    if (defined $self->_status->{$cmd}) {
	$self->croak ('Only one ' . $cmd . 'metadata is allowed');
    }
    $self->_status->{$cmd} = $args;
}

sub _parseMetaHandleTextEntry {
    my $self = shift;
    my $cmd = shift;
    my $args = shift;
    
    my $arr = $self->_status->{$cmd};
    if (!$arr) {
	$arr = $self->_status->{$cmd} = [];
    }

    my @args = split (/ /, $args, 2);
    if ($args[0] =~ /^\(([^)]+)\)$/) {
	push ($arr, { AUTHOR => $1, TEXT => $args[1] });
    } else {
	push ($arr, { TEXT => $args });
    }

    $self->_metaStatus ($cmd);
}

sub _parseMeta {
    my $self = shift;
    my $line = shift;

    # Does it look like a meta-directive?
    return 0 if $line !~ /^\* ([A-Z0-9_]+):( (.*))?/;

    my ($cmd, $args) = ($1, $3);

    return 1 if $self->_parseMetaDesc ($cmd, $args);
    # Don't process other commands if we are within DESC section:
    return 0 if defined $self->_metaStatus && $self->_metaStatus eq 'DESC';

    # All meta directives indicate end of multi-line parsing.
    # We save the metaStatus just in case the meta directive is not recognized.
    my $metaStatus = $self->_metaStatus;
    $self->_clearMetaStatus ();

    switch ($cmd) {
	case 'FMT'   { $self->_parseMetaSingleEntry ('FMT', $args); }
	case 'VER'   { $self->_parseMetaSingleEntry ('VER', $args); }
	case 'TODO'  { $self->_parseMetaHandleTextEntry ('TODO', $args); }
	case 'ISSUE' { $self->_parseMetaHandleTextEntry ('ISSUE', $args); }
	case 'LOG'   { $self->_parseMetaHandleTextEntry ('LOG', $args); }
	case 'NOTE'  { $self->_parseMetaHandleTextEntry ('NOTE', $args); }
	case 'DESC' {
	    # Already handled. Ignore.
	    last;
	}
	case 'AUTHOR' {
	    my @args = split (/ /, $args, 3);
	    $self->carp ('Repeated AUTHOR handle') if exists $self->_status->{'AUTHOR'}{$args[0]};
	    $self->_status->{'AUTHOR'}{$args[0]} = {
		HANDLE => $args[0],
		EMAIL => $args[1],
		NAME => $args[2]
	    };
	}
	case 'DAT' { $self->_status->{DAT} = $args; }
	case 'POP' {
	    my ($city, $state_name) = split (/ ?, ?/, $args, 2);

	    my $state = $self->_status->{STATE}{$state_name};
	    if (!$state) {
		$state = {
		    NAME => $state_name,
		    POP => {}
		};
		$self->_status->{STATE}{$state_name} = $state;
	    }
	    
	    my $key = "$state_name|$city";
	    my $pop = $self->_status->{POP}{$key};
	    if (!$pop) {
		$pop = {
		    CITY => $city,
		    STATE => $state,
		    APT => {}
		};
		$self->_status->{POP}{$key} = $pop;
	    }
	    $state->{POP}{$city} = $pop;
	    $self->_status->{POP_CURR} = $pop;
	}
	case 'APT' {
	    if ($args eq 'END') {
		$self->_status->{APT_CURR} = undef;
		last;
	    }

	    my ($icao, $name) = split (/ /, $args, 2);
	    $self->carp ('Repeated APT ICAO') if exists $self->_status->{APT}{$icao};

	    my $dat = $self->_status->{DAT};
	    if (!$dat) {
		$self->carp ('Missing DAT for APT');
	    }

	    my $pop = $self->_status->{POP_CURR};
	    if (!$pop) {
		$self->carp ('Missing POP for APT');
		$pop = $self->_status->{POP}{UNK};
	    }

	    my $apt = {
		DAT => $dat,
		POP => $pop,
		NOTE => $self->_status->{NOTE},
		ICAO => $icao,
		NAME => $name,
	    };
	    
	    $pop->{APT}{$icao} = $apt;
	    $self->_status->{APT}{$icao} = $apt;
	    $self->_status->{APT_CURR} = $apt;

	    $self->_status->{NOTE} = [];
	}
	else {
	    $self->carp ('Unrecognized metadata');
	    # Recover metaStatus.
	    $self->_metaStatus ($metaStatus);
	    return 0;
	}
    }

    return 1;
}

sub _parseMetaHandleAppendText {
    my $self = shift;
    my $cmd = shift;
    my $line = substr (shift, 1);

    StripLSpace ($line);
    $self->_status->{$cmd}[-1]{TEXT} .= ' ' . $line;
}

sub _parseComment {
    my $self = shift;
    my $line = shift;

    if ($line =~ /^\*/) {
	# A comment. Try processing metadata
	return 1 if $self->_parseMeta ($line);

	# Metadata not found but maybe we are collecting multi-line strings.
	if ($self->_hasMetaStatus) {
	    switch ($self->_metaStatus) {
		case 'LOG'   { $self->_parseMetaHandleAppendText ('LOG', $line); }
		case 'TODO'  { $self->_parseMetaHandleAppendText ('TODO', $line); }
		case 'ISSUE' { $self->_parseMetaHandleAppendText ('ISSUE', $line); }
		case 'NOTE'  { $self->_parseMetaHandleAppendText ('NOTE', $line); }
		case 'DESC' {
		    $line =~ s/^\* ?//;
		    $self->_status->{DESC} .= $line . "\n";
		}
	    }
	}

	return 1;
    }

    # Line is not a comment. Any non-comment finishes multi-line meta parsing.
    $self->_clearMetaStatus ();
    return 0;
}

sub _parseEmptyLine {
    my $self = shift;
    my $line = shift;

    if ($line eq '') {
	# Empty lines interrupt multi-line parsing.
	$self->_clearMetaStatus ();
	return 1;
    }
    return 0;
}

sub parseLine {
    my $self = shift;
    my $line = shift;

    # Strip leading/trailing spaces.
    StripLTSpace ($line);
    $line =~ s/\s+/ /g;

    $self->_lineStr ($line);
    $self->lineNum ($self->lineNum + 1);

    return if $self->_parseEmptyLine ($line);

    # Try parsing comments, which may have metadata directives inside.
    return if $self->_parseComment ($line);

    # OK, we have a command.
    $self->_parseCommand ($line);
}

sub read {
    my $self = shift;
    my $fd = shift;

    return undef if eof ($fd);
    my $line = <$fd>;
    Carp::croak $! if !defined ($line);
    $self->parseLine ($line);
    return 1;
}

sub readFile {
    my $self = shift;
    my $fname = shift;

    open my $fd, $fname || croak;
    while ($self->read ($fd)) 
    {}
    close $fd;

    return 1;
}

# Tell the parser we are done to perform some final checks.
sub finish {
    my $self = shift;

    if ($self->_metaStatus eq 'DESC') {
	croak ('DESC section not closed');
    }
}

__PACKAGE__->meta->make_immutable;
