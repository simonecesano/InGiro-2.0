package InGiro::Controller::Points;

use Mojo::Base qw/Mojolicious::Controller -signatures/;
use Mojo::Loader qw(data_section);
use Mojo::Util qw/dumper/;

use Hash::Merge qw/merge/;

sub get_points ($c) {
    my $params = merge ($c->req->params->to_hash, ($c->req->json || {}));

    $c->log->info(dumper $params);
    if ($params->{around}) {
	# reply from around point
	$c->get_items_around_p([ split /\s*\,\s*/, $params->{around}]);
    }
    elsif ($params->{from} && $params->{to}) {
	# reply from from/to params
	my $points = [ [ reverse split /\s*\,\s*/, $params->{from} ], [ reverse split /\s*\,\s*/, $params->{to} ] ];
	$c->get_points_on_route({ points => $points, profile => "car", avoid => [] } );
    }
    elsif ($params->{points}) {
	# reply from list of points
	$c->reply->json_exception("Bad request")
    }
    elsif ($params->{route}) {
	# reply from route as encoded polyline
	$c->reply->json_exception("Bad request")
	# $c->get_points_on_route(@_);
    }
    elsif ($params->{map}) {
	# reply from existing map
	$c->reply->json_exception("Bad request")
	# $c->get_points_on_route(@_);
    }
    else {
	$c->reply->json_exception("Bad request")
    }
}

sub get_items_around_p {
    my $c = shift;
    my $later = $c->render_later->tx;
    $c->pg->db->items_around_p(shift())
	->then(sub {
		   $c->render(json => { points => $_[0]->expand->hashes })
	       });
}

sub get_points_on_route {
    my $c = shift;
    my $json = shift;

    my $later = $c->render_later->tx;
    my ($route, $directions);

    $c->api->graphhopper->directions_p($json)
	->then(sub {
		   my $tx = shift;
		   $directions = $tx->res->json;
		   $route = $directions->{paths}->[0]->{points};
	       })
	->then(sub {
		   $c->pg->db->items_along_route_p($route, $json->{distance}, $json->{class});
	       })
	->then(sub {
		   $c->render(json => merge( $directions, { points => $_[0]->expand->hashes }))
	       })
}

1
