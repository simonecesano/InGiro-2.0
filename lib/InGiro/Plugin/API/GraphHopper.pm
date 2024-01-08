package InGiro::Plugin::API::GraphHopper;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/dumper/;

sub register {
    my ($self, $app) = @_;
    $app->log->info("registering empty package " .  __PACKAGE__);
    # $app->helper(directions_p => sub {
    # 		     my $self = shift;
    # 		     my $json = shift;
    # 		     $app->log->info(ref $self);
    # 		     my $url = Mojo::URL->new('https://graphhopper.com/api/1/route?key=00182e2c-a3a7-40a9-a172-133da2a0b37b&elevation=true');
    # 		     my $tx = $app->ua->build_tx(POST => $url => json => $json);
    # 		     return $app->ua->start_p($tx)
    # 		 });
}

1

