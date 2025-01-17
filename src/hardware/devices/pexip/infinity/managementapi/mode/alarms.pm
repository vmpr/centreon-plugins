#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package hardware::devices::pexip::infinity::managementapi::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'alarm [level: %s] [name: %s] [details: %s] %s',
        $self->{result_values}->{level},
        $self->{result_values}->{name},
        $self->{result_values}->{details},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{opened})
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'alarms', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => { nlabel => 'alerts.problems.current.count', min => 0 },
          group => [ { name => 'alarm', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{alarm} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{level} =~ /warning|minor/i',
            critical_default => '%{level} =~ /critical|major|error/i',
            set => {
                key_values => [ { name => 'name' }, { name => 'level' }, { name => 'details' }, { name => 'opened' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'memory'        => { name => 'memory' }
    });

    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => 'Date::Parse',
        error_msg => "Cannot load module 'Date::Parse'."
    );
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{alarms}->{global} = { alarm => {} };
    my $results = $options{custom}->request_api(endpoint => '/api/admin/status/v1/alarm/');

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_pexip_' . $options{custom}->get_hostname()  . '_' . $options{custom}->get_port(). '_' . $self->{mode});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my ($i, $current_time) = (1, time());
    foreach my $alarm (@$results) {
        my $create_time = Date::Parse::str2time($alarm->{time_raised}, 'UTC');
        if (!defined($create_time)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "Can't Parse date '" . $alarm->{time_raised} . "'"
            );
            next;
        }

        next if (defined($self->{option_results}->{memory}) && defined($last_time) && $last_time > $create_time);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $alarm->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $alarm->{name} . "': no matching filter.", debug => 1);
            next;
        }

        my $diff_time = $current_time - $create_time;

        $self->{alarms}->{global}->{alarm}->{$i} = {
            %$alarm,
            opened => $diff_time
        };
        $i++;
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}
        
1;

__END__

=head1 MODE

Check alarms.

=over 8

=item B<--filter-name>

Filter by alert name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (Default: '%{level} =~ /warning|minor/i')
You can use the following variables: %{level}, %{details}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (Default: '%{level} =~ /critical|major|error/i').
You can use the following variables: %{level}, %{details}, %{name}

=item B<--memory>

Only check new alarms.

=back

=cut
