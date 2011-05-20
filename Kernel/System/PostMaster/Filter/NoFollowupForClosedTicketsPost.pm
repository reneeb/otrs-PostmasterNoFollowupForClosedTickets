package Kernel::System::PostMaster::Filter::NoFollowupForClosedTicketsPost;

use strict;
use Kernel::System::Ticket;

use vars qw($VERSION);
$VERSION = '$Revision: 1.4 $';
$VERSION =~ s/^.*:\s(\d+\.\d+)\s.*$/$1/;

sub new {
    my $Type = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless ($Self, $Type);

    $Self->{Debug} = $Param{Debug} || 0;

    # get needed opbjects
    for my $Object (
        qw(ConfigObject LogObject DBObject ParseObject TimeObject MainObject EncodeObject)
    ) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    $Self->{TicketObject} = Kernel::System::Ticket->new( %{$Self} );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(TicketID JobConfig GetParam)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message => "Need $Needed!",
            );
            return;
        }
    }


    return 1 if !$Param{GetParam}->{'X-OTRS-LinkToTicket'};
    return 1 if !$Self->{ConfigObject}->Get('NoFollowupFilter::LinkTicket');

    $LinkObject->LinkAdd(
        SourceObject => 'Ticket',
        SourceKey    => $Param{GetParam}->{'X-OTRS-LinkToTicket'},
        TargetObject => 'Ticket',
        TargetKey    => $Param{TicketID},
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => 1,
    );


    return 1;
}

1;
