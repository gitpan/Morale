#
# Morale.pm
#
# A Perl module for dealing with morale files and calculating
# company morale.
#
# TODO: Change the calculation of company morale to a timed
# event, instead of doing it real-time, since it could take
# a while for large user sets and/or remote home directories.
#
# TODO: Or, at least cache the current results for N seconds,
# not going back to the source until that expires.
#
# Copyright (C) 1999 Gregor N. Purdy. All rights reserved.
#

package Morale;

use strict;

BEGIN {
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	$VERSION     = 0.001;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&get_morale &set_morale &calc_morale);
	%EXPORT_TAGS = ( );
	@EXPORT_OK   = qw(&morale_file);
}
use vars qw($top $my_scale $co_scale $bar $my_morale $co_morale);
use Carp;


my %morales;


#
# morale_file()
#

sub morale_file
{
	my ($user) = @_;
	my $dir;
	my @check;

	if (!defined($user)) { $user = (getpwuid($>))[0]; }

	$dir = (getpwnam($user))[7];
	
	push @check, "/var/morale/$user";
	push @check, "$dir/.morale";

	foreach (@check) { if (-r $_) { return $_; } }

	return "$dir/.morale";
}


#
# validate_morale()
#

sub validate_morale
{
	my ($morale) = @_;

	if (defined($morale)) {
		$morale =~ s/^\s*(.*)\s*$/$1/;

		if    (!($morale =~ m/^[0-9]+$/))        { undef $morale; }
		elsif (($morale < 0) or ($morale > 100)) { undef $morale; }
	}

	return $morale;
}


#
# set_morale()
#

sub set_morale
{
	my ($morale, $user) = @_;
	my $file = morale_file($user);

	$morale = validate_morale($morale);

	if (!defined($morale)) {
		system "rm -f $file";
		return;
	}

	if (!open(MORALE, ">$file")) {
		carp "Couldn't open file `$file' for writing.";
		return;
	}

	print MORALE "$morale\n";
	close MORALE;
}


#
# get_morale()
#
# Returns the morale for the given user, or the current user if none given.
#

sub get_morale
{
	my ($user) = @_;

	my $file = morale_file($user);
	my $morale;

	open MORALE, "<$file"
		or return undef;
	$morale = <MORALE>;
	close MORALE;

	chomp $morale;	

	return validate_morale($morale);
}


#
# get_all_morales()
#
# Returns the intializer for a hash of user-morale associations.
#

sub get_all_morales
{
	my $user;
	my @users;

	%morales = ( );

	setpwent();
	while ($user = getpwent) { push @users, $user; }
	endpwent();
	
	foreach $user (@users) {
#		print STDERR "$user: ";
		my $user_morale = get_morale($user);

		if (defined($user_morale)) {
#			print STDERR "$user_morale\n";
			$morales{$user} = $user_morale;
		} else {
#			print STDERR "<undef>\n";
		}
	}

	return %morales;
}


#
# calc_morale()
#

sub calc_morale
{
	my $total_morale = 0;
	my $count_morale = 0;

	get_all_morales();

	foreach (sort keys %morales) {
#		print STDERR "$_: $morales{$_}\n";
		$total_morale += $morales{$_};
		$count_morale ++;
	}

	if ($count_morale < 1) { return undef; }
	else                   { return $total_morale / $count_morale; }
}


#
# Return a true value:
#

1;


#
# End of file.
#

