package InGiro::Plugin::API::Graphhopper;
use Mojo::Base -base;

use Mojo::Util qw/dumper/;

has "app";

sub directions_p {
    my $self = shift;
    my $json = shift;

    my $url = Mojo::URL->new('https://graphhopper.com/api/1/route?key=00182e2c-a3a7-40a9-a172-133da2a0b37b&elevation=true');
    my $tx = $self->app->ua->build_tx(POST => $url => json => $json);
    return $self->app->ua->start_p($tx)
};

1

