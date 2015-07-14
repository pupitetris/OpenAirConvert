#!/usr/bin/perl

use lib './lib';
use warnings qw(FATAL);

use OpenAir;

$a = OpenAir->new ();
$a->readFile ($ARGV[0]);

1;
