#!/usr/bin/env perl
# merge-all.pl
# Mike Covington
# created: 2013-04-29
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';
use File::Path 'make_path';

my @sample_file_list = @ARGV;
my $genotyping_dir = "/Volumes/Runner_3A/mike/RMDUP.NR_1/merged.uncontam/";
my @chromosomes = qw(A01 A02 A03 A04 A05 A06 A07 A08 A09 A10);

my %samples;
for (@sample_file_list) {
    my ($id) = $_ =~ m/(RIL_\d+\w?)\./;
    $samples{$id}++;
}

make_path("$genotyping_dir/merged.all/genotyped");
my %db;
for my $sample ( keys %samples ) {
    for my $chr (@chromosomes) {
        my $sample_file = "$genotyping_dir/genotyped/$sample.$chr.genotyped.nr";
        open my $sample_fh, "<", $sample_file;
        add_sample( $sample, $sample_fh, \%db);
        close $sample_fh;
    }
}

for my $chr (@chromosomes) {
    open my $out_fh, ">", "$genotyping_dir/merged.all/genotyped/all.$chr.genotyped.nr";

    for my $pos ( sort { $a <=> $b } keys $db{$chr} ) {
        say $out_fh join "\t", $chr, $pos, $db{$chr}{$pos}{"par1"},
          $db{$chr}{$pos}{"par2"}, $db{$chr}{$pos}{"tot"};
    }

    close $out_fh;
}

sub add_sample {
    my ( $sample, $fh, $db_ref ) = @_;
    while (<$fh>) {
        chomp $_;
        my ( $chr, $pos, $par1, $par2, $tot ) = split /\t/, $_;
        $$db_ref{$chr}{$pos}{"par1"} += $par1;
        $$db_ref{$chr}{$pos}{"par2"} += $par2;
        $$db_ref{$chr}{$pos}{"tot"}  += $tot;
    }
}

exit;
