# Copyright (C) 2004 Domingo Alc�zar Larrea
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the version 2 of the GNU General
# Public License as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307


package DIME::Tools;

use 5.008;
use strict;
use warnings;


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DIME ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DIME::Tools - modules for parsing and generate DIME messages

=head1 SYNOPSIS

	Generating DIME messages
	========================

		my $payload = new DIME::Payload;
		$payload->attach(Path => "/mydata/index.html",
		                 MIMEType => 'text/html',
		                 Dynamic => 1);

		my $payload2 = new DIME::Payload;
		$payload2->attach( Data => "HELLO WORLD!!!",
		                   MIMEType => 'text/plain' );

		my $message = new DIME::Message;

                my $payload = new DIME::Payload;
                $payload->attach(Path => "/mydata/index.html",
                                 MIMEType => 'text/html',
                                 Dynamic => 1);
		$message->add_payload($payload);
		$message->add_payload($payload2);

		# Print the encoded message to STDOUT
		$message->print(\*STDOUT);

	Parsing DIME messages
	=====================

	        my $parser = new DIME::Parser();

		# Open a file with a dime encoded message
	        $f = new IO::File("dime.message","r");
	        my $message = $parser->parse($f);
	        $f->close();
		
		# Print the content of each payload to STDOUT
	        for my $i ($message->payloads())
	        {
	                print $i->print_content(\*STDOUT);
	        }
	
 
=head1 DESCRIPTION

DIME-tools is a collection of DIME:: modules for parse and generate DIME encoded messages ( Direct Internet Message Encapsulation ). DIME-tools support single-record and chunked payloads for sending big attachments.

=head1 GENERATING MESSAGES

For any content you want to send in a message, you have to create a Payload object:

	my $payload = new DIME::Payload;
        $payload->attach(Path => "/mydata/index.html",
                         MIMEType => 'text/html',
                         Dynamic => 1);

With the attach method you can specify the next keys:

	Path: the name of the file you want to attach to the payload object. If the data you want to attach isn't in a file, you can use the Data key.

	Data: it's the reference to a scalar in which you store the data you want to attach.

	Dynamic: if Path is declared, the data is not loaded fully in memory. The only that you attach to the payload object is the name of the file of the Path key, not the content itself.

	Chunked: if it's declared, it represents the size of the chunk records in bytes. If you don't declare it, the message will not be chunked.

	MIMEType: the type of the payload. It must be a string with a MIME standard type. Other possibility is to use URIType.

	URIType: specifies an URI that defines that type of the content.

=head1 ATTACH A PAYLOAD TO A MESSAGE

	my $message = new DIME::Message;
	$message->add_payload($payload);

=head1 PRINT A ENCODED MESSAGE

	# Print prints to any IO::Handle
	$message->print(\*STDOUT);

	or
	
	# print_data returns a reference to a scalar
	print ${$message->print_data()};

=head1 PARSING MESSAGES

All you have to do is create a DIME::Parser object and call the parse method with a IO::Handle to a DIME message. Then you can iterate over the $message->payloads() array to get the contents of the message:

	my $parser = new DIME::Parser();
	$f = new IO::File("dime.message","r");
	my $message = $parser->parse($f);
	$f->close();
	for my $i ($message->payloads())
	{
	        print $i->print_content(\*STDOUTs);
	}

You can also call to parse_data if you have a DIME message in a scalar variable:
	
	my $dime_message;
	my $message = $parser->parse_data(\$dime_message);

And call print_content_data if what you want is to get a reference to the content-data.

=head1 SEE ALSO

Direct Internet Message Encapsulation draft:
 http://www.gotdotnet.com/team/xml_wsspecs/dime/dime.htm

=head1 AUTHOR

Domingo Alcazar Larrea, E<lt>dalcazar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE


Copyright (C) 2004 Domingo Alc�zar Larrea

This program is free software; you can redistribute it and/or
modify it under the terms of the version 2 of the GNU General
Public License as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307

=cut
