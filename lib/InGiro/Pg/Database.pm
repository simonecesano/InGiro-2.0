package InGiro::Pg::Database;

use Mojo::Base qw/Mojo::Pg::Database/;
use Mojo::Loader qw(data_section);

local $\ = "\n";

sub geojson_to_bbox {
    my $res = shift;
    [ @{$res->{bbox}->{coordinates}->[0]->[0]}, @{$res->{bbox}->{coordinates}->[0]->[2]} ]
}

sub class_to_placeholder {
    my $class = (uc shift);
    my @classes = ('A'..($class || 'C'));
    my $classes_placeholder = join ', ', map { '?' } @classes;
    return ($classes_placeholder, @classes);
}

sub route_to_bbox_p {
    my ($self, $polyline, $distance, $bbox) = @_;
    $distance //= 5000;

    $self->query_p(
		       "select ST_AsGeoJSON(ST_extent(st_buffer(ST_SetSRID(ST_LineFromEncodedPolyline(?), 4326)::geography, ?)::geometry))::json as bbox",
		       $polyline,
		       $distance
		      )
	->then(sub {
		   my $got = shift;
		   my $res = $got->expand->hashes->first;
		   return $bbox ? geojson_to_bbox($res) : $res;
	       })

};

sub extent_to_bbox_p {
    my ($self, $latlon, $distance, $bbox) = @_;
    $distance //= 5000;

    $self->query_p(
		       "select ST_AsGeoJSON(ST_extent(st_buffer(ST_SetSRID(ST_Point(?, ?), 4326)::geography, ?)::geometry))::json as bbox",
		       $latlon->[0], $latlon->[1],
		       $distance
		      )
	->then(sub {
		   my $got = shift;
		   my $res = $got->expand->hashes->first;
		   return $bbox ? geojson_to_bbox($res) : $res;
	       })

};


sub items_around_p {
    my ($self, $latlon, $distance, $class) = @_;
    $distance //= 5000;
    my ($classes_placeholder, @classes) = class_to_placeholder($class);

    my $sql = sprintf(data_section(__PACKAGE__, "around_point.sql"), $classes_placeholder);

    $self->extent_to_bbox_p($latlon, $distance, 1)
	->then(sub {
		   my $bbox = shift;
		   $self->query_p($sql, @$bbox, @$latlon, $distance, @classes)
	       })

};

sub items_along_route_p {
    my ($self, $polyline, $distance, $class) = @_;
    $distance //= 5000;

    my ($classes_placeholder, @classes) = class_to_placeholder($class);
    my $sql = sprintf(data_section(__PACKAGE__, "along_route.sql"), $classes_placeholder);

    $self->route_to_bbox_p($polyline, $distance, 1)
	->then(sub {
		   my $bbox = shift;
		   return $self->query_p($sql, @$bbox, $polyline, $distance, @classes)
	       })
	->then(sub {
		   my $d = shift;
		   local $\ = "\n";
		   return $d;
	       });
}

sub items_in_bbox_p {
    my ($self, $bbox, $class) = @_;

};


1

__DATA__
@@ along_route.sql
select "entity_id", "map_category", "entity_class", "picture", "lat", "lng"
FROM "wikidata" WHERE 
     "entity_id" in (SELECT "entity_id" FROM "wikidata" WHERE lng > ? and lat > ? and lng < ? and lat < ? and hide = false)
     and ST_contains(st_buffer(ST_SetSRID(ST_Simplify(ST_LineFromEncodedPolyline(?), 0.001), 4326)::geography, ?)::geometry, location::geometry)
     and entity_class in (%s)
;
@@ around_point.sql
select "entity_id", "map_category", "entity_class", "picture", "lat", "lng"
FROM "wikidata" WHERE 
     "entity_id" in (SELECT "entity_id" FROM "wikidata" WHERE lng > ? and lat > ? and lng < ? and lat < ? and hide = false)
     and ST_contains(st_buffer(ST_SetSRID(ST_Point(?, ?), 4326)::geography, ?)::geometry, location::geometry)
     and entity_class in (%s)
;
