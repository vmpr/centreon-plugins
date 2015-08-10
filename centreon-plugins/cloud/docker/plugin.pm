#
# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::docker::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                        'blockio'           => 'apps::docker::mode::blockio',
                        'containerstate'    => 'apps::docker::mode::containerstate',
                        'cpu'               => 'apps::docker::mode::cpu',
                        'image'             => 'apps::docker::mode::image',
                        'info'              => 'apps::docker::mode::info',
                        'list-containers'   => 'apps::docker::mode::listcontainers',
                        'memory'            => 'apps::docker::mode::memory',
                        'traffic'           => 'apps::docker::mode::traffic',
                        );
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Docker and containers through its API.
Requirements: Docker 1.7.1+ and Docker API 1.19+

=cut
