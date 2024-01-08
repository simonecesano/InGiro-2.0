package InGiro::Plugin::API::Wikidata;
use Mojo::Base -base;
use Mojo::URL;
use Mojo::Loader qw/data_section/;
use Mojo::Promise;

use Mojo::Util qw/dumper decamelize/;

use Hash::Merge qw/merge/;
use List::MoreUtils qw/uniq/;

has "app";


sub around_p {
    my $self = shift;
    my $point = shift;

    my $distance = shift || 5;
    my $sparql = sprintf(data_section(__PACKAGE__, "around.sparql"), $point->@*, $distance);
    # $self->app->log->info($sparql);

    return Mojo::Promise->reject("No bounding box provided") unless $point && (ref $point eq "ARRAY") && 2 == scalar $point->@*;

    my $url = Mojo::URL->new('https://query.wikidata.org/sparql');
    $url->query({ query => $sparql, format => "json" });

    my $tx = $self->app->ua->build_tx(GET => $url);
    return $self->app->ua->start_p($tx)
}

sub inside_p {
    my $self = shift;
    my $bbox = shift;

    # fix for wikidata
    $bbox = [ @{$bbox}[0, 1, 2, 3] ];

    my $sparql = sprintf(data_section(__PACKAGE__, "inside.sparql"), $bbox->@*);
    # $self->app->log->info(dumper $bbox);
    # $self->app->log->info("\n" . $sparql);

    return Mojo::Promise->reject("No bbox provided") unless $bbox && (ref $bbox eq "ARRAY") && (4 == scalar grep { /\d/ } $bbox->@*);
    unless (($bbox->[0] < $bbox->[2])  # SW_LNG < NE_LNG
	    &&
	    ($bbox->[1] > $bbox->[3])) # SW_LAT < NE_LAT
	{
	    return Mojo::Promise->reject("Invalid bbox")
	}

    my $url = Mojo::URL->new('https://query.wikidata.org/sparql');
    $url->query({ query => $sparql, format => "json" });

    my $tx = $self->app->ua->build_tx(GET => $url);
    return $self->app->ua->start_p($tx);
}

1
__DATA__
@@ inside.sparql
#defaultView:Map
SELECT ?place ?placeCoords ?placeCategory ?placePicture ?placeLabel WHERE {
  SERVICE wikibase:box {
    ?place wdt:P625 ?location .
    # looks like cornerwest must be south of cornereast
    # otherwise you go around the globe
    # this is lng lat
    #                                          SW_LNG SW_LAT
    #                                          NE_LNG NE_LAT
    bd:serviceParam wikibase:cornerWest "Point(%f %f)"^^geo:wktLiteral .
    bd:serviceParam wikibase:cornerEast "Point(%f %f)"^^geo:wktLiteral .
  }
  ?place wdt:P31  ?placeCategory .
  ?place wdt:P625 ?placeCoords   .

  # optional { SERVICE wikibase:label { bd:serviceParam wikibase:language "en, de, it, fr, es" } }
  # optional { SERVICE wikibase:description { bd:serviceParam wikibase:language "en, de, it, fr, es" } }
  optional{ ?place wdt:P18 ?placePicture . }
}

@@ around.sparql
#defaultView:Map
SELECT ?place ?placeCoords ?placeCategory ?placePicture ?placeLabel WHERE {
    SERVICE wikibase:around {
      # this is lng lat
      ?place wdt:P625 ?coords .
      bd:serviceParam wikibase:center "Point(%f %f)"^^geo:wktLiteral .
      bd:serviceParam wikibase:radius "%f" .
    }

  ?place wdt:P31  ?placeCategory .
  ?place wdt:P625 ?placeCoords   .

  # optional { SERVICE wikibase:label { bd:serviceParam wikibase:language "en, de, it, fr, es" } }
  optional{ ?place wdt:P18 ?placePicture . }
}
