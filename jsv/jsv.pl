#!/usr/bin/perl
use Data::Dumper;
use strict;
use warnings;
no warnings qw/uninitialized/;

use Env qw(SGE_ROOT);
use lib "$SGE_ROOT/util/resources/jsv";
use JSV qw( :DEFAULT jsv_sub_get_param jsv_sub_add_param jsv_log_warning jsv_log_info);

sub expand_unit_multiplier($) {
	my $arg=shift;
	
	if ( $arg =~ /^([0-9.]+)([kKmMgG]?)$/ ) {
		my $num=$1;
		my $unit=$2;
		if ( $unit ) {
			my $multiplier=1;

			if ( $unit eq "k" ) {
				$multiplier=1000;
			} elsif ( $unit eq "K" ) {
				$multiplier=1024;
			} elsif ( $unit eq "m" ) {
				$multiplier=1000**2;
			} elsif ( $unit eq "M" ) {
				$multiplier=1024**2;
			} elsif ( $unit eq "g" ) {
				$multiplier=1000**3;
			} elsif ( $unit eq "G" ) {
				$multiplier=1024**3;
			}

			return $num * $multiplier;

		} else { 
			return $num;
		}
	} 

	return undef;
}

sub adjust_min_memory_complex_limit($$$) {
	my $min_mem_limit=shift;
	my $hard=shift;
	my $limit_name=shift;

	my $limit_type='hard';
	if ( ! $hard ) {
		$limit_type='soft';
	}

	# Expand the minimum memory limit and ensure we succeeded
	my $expanded_min_mem_limit=expand_unit_multiplier($min_mem_limit);
	if ( ! defined($expanded_min_mem_limit) ) {
		jsv_reject("Error! Internal JSV ERror: $limit_type minimum memory limit '$min_mem_limit' specified for '$limit_name' is invalid");
	}

	# Get the current value of the specified limit 
	my $mem_limit=jsv_sub_get_param("l_$limit_type",$limit_name);
	if ( $mem_limit ) {
		my $expanded_mem_limit=expand_unit_multiplier($mem_limit);
		if ( defined($expanded_mem_limit) ) {
			if ( $expanded_min_mem_limit >= $expanded_mem_limit ) {
				jsv_sub_add_param("l_$limit_type",$limit_name,$min_mem_limit);
				jsv_log_info("Increasing low $limit_type $limit_name resource request '$mem_limit' to '$min_mem_limit'");
			}
		} else {
			jsv_reject("Error! Invalid $limit_type $limit_name value '$min_mem_limit' specified.");
		}
	}
}		

sub remove_env_var($) {
	my $env_var=shift;


}

jsv_on_verify(sub {
	adjust_min_memory_complex_limit('128M',1,'h_vmem');
	adjust_min_memory_complex_limit('128M',1,'s_vmem');
	remove_env_var("module()");
	jsv_accept();
});


jsv_on_start(sub{
	return
});

jsv_main();
