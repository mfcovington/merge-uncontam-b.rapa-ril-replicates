#!/usr/bin/env perl
# replicate-merger.pl
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
use POSIX qw(strftime);

my $genotyping_dir = "/Volumes/Runner_3A/mike/RMDUP.NR_1/";
my $uncontam_file = "$genotyping_dir/reps.uncontam.20130501";
my $sample_table_file = "sampleID_replicateID.20130430.tsv";
my @chromosomes = qw(A01 A02 A03 A04 A05 A06 A07 A08 A09 A10);

open my $uncontam_fh, "<", $uncontam_file;
my %uncontam = map { chomp; $_ => 1 } <$uncontam_fh>;
close $uncontam_fh;

open my $sample_table_fh, "<", $sample_table_file;
my %sample_table;
for (<$sample_table_fh>) {
    chomp;
    my ( $sample_id, $rep_id ) = split /\t/;
    next unless $sample_id =~ m/^RIL_\d+\w?$/;
    next unless exists $uncontam{$rep_id};
    push @{ $sample_table{$sample_id} }, $rep_id;
}
close $sample_table_fh;

my $date = strftime "%Y%m%d", localtime;
my $out_dir = "$genotyping_dir/merged.uncontam.$date/genotyped";
make_path("$out_dir");
for my $sample ( keys %sample_table ) {
    my %db;
    for my $rep ( @{ $sample_table{$sample} } ) {
        for my $chr (@chromosomes) {
            my $rep_file = "$genotyping_dir/genotyped/$rep.$chr.genotyped.nr";
            open my $rep_fh, "<", $rep_file;
            add_rep( $rep, $rep_fh, \%db);
            close $rep_fh;
        }
    }
    for my $chr (@chromosomes) {
        open my $out_fh, ">", "$out_dir/$sample.$chr.genotyped.nr";

        for my $pos ( sort { $a <=> $b } keys $db{$chr} ) {
            say $out_fh join "\t", $chr, $pos, $db{$chr}{$pos}{"par1"},
              $db{$chr}{$pos}{"par2"}, $db{$chr}{$pos}{"tot"};
        }

        close $out_fh;
    }
}

sub add_rep {
    my ( $rep, $fh, $db_ref ) = @_;
    while (<$fh>) {
        chomp $_;
        my ( $chr, $pos, $par1, $par2, $tot ) = split /\t/, $_;
        $$db_ref{$chr}{$pos}{"par1"} += $par1;
        $$db_ref{$chr}{$pos}{"par2"} += $par2;
        $$db_ref{$chr}{$pos}{"tot"}  += $tot;
    }
}

exit;
