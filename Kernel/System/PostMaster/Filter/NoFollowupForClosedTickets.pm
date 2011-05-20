package Kernel::System::PostMaster::Filter::NoFollowupForClosedTickets;

use strict;
use Kernel::System::Ticket;
use Kernel::System::State;

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
    $Self->{StateObject}  = Kernel::System::State->new( %{$Self} );

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

    my $Subject = $Param{GetParam}->{Subject};

    return 1 if !$Param{TicketID};


    # get a list of "closed" states
    my @Closed = $Self->{StateObject}->StateGetStatesByType(
        StateType => [ 'closed' ],
        Result    => 'Name',
    );

    my %Ticket = $Self->{TicketObject}->TicketGet(
        TicketID => $Param{TicketID},
    );

    # if the ticket is not a closed one, just return
    return 1 if !grep{ $Ticket{State} }@Closed;

    # remove ticket number from subject
    my $Subject           = $Param{Subject} || '';
    my $Tn                = $Self->{TicketObject}->GetTNByString($Subject);
    my $TicketHook        = $Self->{ConfigObject}->Get('Ticket::Hook');
    my $TicketHookDivider = $Self->{ConfigObject}->Get('Ticket::HookDivider');

    $Param{GetParam}->{Subject} =~ s{ . \Q $TicketHook$TicketHookDivider$Tn \E . }{};

    # link tickets / write a corresponding postmaster post filter
    $Param{GetParam}->{'X-OTRS-LinkToTicket'}         = $Param{TicketID};
    $Param{GetParam}->{'X-OTRS-IgnoreFollowUpSearch'} = 1;

    return 1;
}

1;
