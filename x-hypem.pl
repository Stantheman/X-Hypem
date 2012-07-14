#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use MP3::Tag;
use LWP::UserAgent;
use HTTP::Cookies;
use FindBin qw($Bin);

my $song_path   = shift @ARGV || "$Bin/hype_songs";
mkdir($song_path) unless (-d $song_path) or die "Couldn't make $song_path: $!";

my $ua = LWP::UserAgent->new(
	agent 	=> 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.',
	timeout	=> 20
);
$ua->cookie_jar(HTTP::Cookies->new(file => "cookies.txt", autosave => 1));		

my $response = $ua->get('http://hypem.com/popular/noremix');
die "Response returned an error: $response->error_as_HTML" if $response->is_error;	
my @source = split(/\n/, $response->decoded_content);
my @songinfo = ();									

foreach my $line (@source) {
	next if ($line !~ m/^\s*(id:|key: |artist:|song:)'(.*)',/);
	push @songinfo,$2;

	if ($1 eq 'song:') {
		my $file = _getsong($ua , \@songinfo);
		
		my $mp3 = MP3::Tag->new("$file");
		$mp3->update_tags( {
			"title" => $songinfo[3],
			"artist" => $songinfo[2],
		});
		@songinfo = ();				
	}
}											

# array: 0=id, 1=key, 2=artist, 3=song
sub _getsong {
	$ua = shift;
	my $songinfo = shift;
	(my $unixtitle = $songinfo->[3]) =~ s/(\s|\/)/_/g;
	(my $unixartist = $songinfo->[2]) =~ s/(\s|\/)/_/g;
	my $file = "$song_path/$unixartist-$unixtitle.mp3";
	
	my $response = $ua->get("http://www.hypem.com/serve/source/$songinfo->[0]/$songinfo->[1]");
	
	unless (-e $file){		#unless file does not exist, download
		$ua->mirror(decode_json($response->decoded_content)->{url} , $file);
	}
	return $file;
}
