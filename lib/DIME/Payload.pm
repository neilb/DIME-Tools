# Copyright (C) 2004 Domingo Alcázar Larrea
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


package DIME::Payload;

use 5.008;
use strict;
use warnings;

use Data::UUID;
use DIME::Record;
use IO::Scalar;

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


sub new
{
	my $class = shift;
	my @records;
	my $this = {			
			_RECORDS => \@records,
			_CHUNK_SIZE => 0,
			_STREAM => undef,
			_BUFFER_SIZE => 1024,
			_MB => 0,
			_ME => 0,
			_TYPE => undef,
			_TNF => 3,
			_ID => undef,
			_FIRST_RECORD => 1,
		};
	my $self = bless $this, $class;
	$self->generate_uuid();
	return $self;
}


sub generate_uuid
{
        my $self = shift;
        # Generate a new UUID to identify the record
        my $duuid = new Data::UUID;
        my $uuid = 'uuid:'.$duuid->create_str();
        $self->id($uuid);
}

sub type
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_TYPE} = $param;
        }
        else
        {
                return $self->{_TYPE};
        }
}

sub mb
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_MB} = $param;
        }
        else
        {
                return $self->{_MB};
        }
}


sub me
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_ME} = $param;
        }
        else
        {
                return $self->{_ME};
        }
}

sub tnf
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_TNF} = $param;
        }
        else
        {
                return $self->{_TNF};
        }
}


sub id
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_ID} = $param;
        }
        else
        {
                return $self->{_ID};
        }
}


# Add a Record to a Payload
sub add_record
{
        my $self = shift;
        my $record = shift;
        push(@{$self->{_RECORDS}},$record);
}


sub attach
{
        my $self = shift;
        my %params = @_;

	my $data;		
	
	$self->{_CHUNK_SIZE} = $params{Chunked} if(defined($params{Chunked}));

 	if(defined($params{Path}))
        {
	        my $file = new IO::File($params{Path},"r");
                if($file)
                {

			# The user wants to load all the file in memory now...
			if(!defined($params{Dynamic}))
			{
		                # Load the attachment from a file

	                	my $buf;
	                        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = $file->stat();
	                        $file->read($buf,$size);
	                        $file->close();                        
	                        $data = \$buf; 
			}
			else
			{
				# Assign the opened stream to the member variable
				$self->{_STREAM} = $file;
			}
		}
        }

        if(defined($params{Data}))
        {
                # Get the attachment directly from memory
                $data = $params{Data};
        }

	$self->set_mime_type($params{MIMEType}) if (defined($params{MIMEType}));
	$self->set_uri_type($params{URIType}) if (defined($params{URIType}));
       
	# If the data is data already loaded in memory...
        if(defined($data))
	{
	        if(defined($params{Chunked}))
	        {
      			my $data_stream = new IO::Scalar $data;
			my $record;
			for(my $i=0;$record = $self->create_chunk_record($data_stream);$i++)
			{
				$self->add_record($record);
			}
			$data_stream->close();
	        }
	        else
	        {
        			# The attachment goes in one record
        		
	        		my $record = new DIME::Record($self);
        		
				my $data_io = new IO::Scalar $data;
		                $record->data($data_io); 

			        $self->add_record($record);
	        }
        }
}

sub print
{
	my $self = shift;
	my $out = shift;
	if(defined($self->{_STREAM}))
	{
		if($self->{_CHUNK_SIZE})
		{
			my $i=0;
			while(my $record = $self->create_chunk_record($self->{_STREAM}))
			{
				$record->mb(1) if($self->mb() and $i==0);
				$record->me(1) if($self->me() and $self->{_STREAM}->eof());
				$record->print($out);
				$i++;
			}
		}
		else
		{
			my $record = new DIME::Record($self);
			$record->data($self->{_STREAM});
			$record->mb(1) if($self->mb());
			$record->me(1) if($self->me());
			$record->print($out);
		}
	}
	else
	{
		my @records = @{$self->{_RECORDS}};
		my $howmany = @records;
		for(my $i=0;$i<$howmany;$i++)
		{
			$records[$i]->mb(1) if($self->mb() and $i==0);
			$records[$i]->me(1) if($self->me() and $i==$howmany-1);
			$records[$i]->print($out);
		}
	}
}

sub print_content
{
	my $self = shift;
	my $io = shift;
	my $buf;
	for my $r (@{$self->{_RECORDS}})
	{
		$r->print_content($io);
	}
}

sub print_content_data
{
	my $self = shift;
	my $data;
	my $io = new IO::Scalar \$data;
	$self->print_content($io);
	$io->close();
	return \$data;
}

sub print_data
{
	my $self = shift;
	my $data;
	my $io = new IO::Scalar \$data;
	$self->print($io);
	$io->close();
	return \$data;
}

sub print_chunk_data
{
	my $self = shift;
	my $data;
	my $io = new IO::Scalar \$data;
	$self->print_chunk($io);
	$io->close();
	return \$data;
}

sub print_chunk
{
	my $self = shift;
	my $out = shift;
	if(defined($self->{_STREAM}) and $self->{_CHUNK_SIZE})
	{
		my $record;
		if($record = $self->create_chunk_record($self->{_STREAM}))
		{
			$record->print($out);
		}
	}
}

# This method takes data from a IO::Handle
# and returns a DIME chunked record with a max size
# of _CHUNK_SIZE bytes

sub create_chunk_record
{
	my $self = shift;
	my $in_stream = shift;

	my $buf;
	my $bytes_read;
	my $record;
	$bytes_read = $in_stream->read($buf,$self->{_CHUNK_SIZE});
	if($bytes_read)
	{
		$record = new DIME::Record($self);
		my $io_data = new IO::Scalar \$buf;
		$record->data($io_data);
		if($self->{_FIRST_RECORD})
		{
			$self->{_FIRST_RECORD} = 0;
			$record->id($self->id());
			$record->chunked(1);
		}
		elsif($in_stream->eof())
		{
			$record->id('');
			$record->set_unchanged_type();
			$record->chunked(0);
		}
		else
		{
			$record->id('');
			$record->set_unchanged_type();
			$record->chunked(1);
		}
	}
	return $record;
}


sub set_mime_type
{
        my $self = shift;
        my $type = shift;
        $self->type($type);
        $self->{_TNF} = 0x01;
}

sub set_uri_type
{
        my $self = shift;
        my $type = shift;
        $self->type($type);
        $self->{_TNF} = 0x02;
}					                	

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DIME - Perl extension for blah blah blah

=head1 SYNOPSIS

  use DIME;
  blah blah blah

=head1 ABSTRACT

  This should be the abstract for DIME.
  The abstract is used when making PPD (Perl Package Description) files.
  If you don't want an ABSTRACT you should also edit Makefile.PL to
  remove the ABSTRACT_FROM option.

=head1 DESCRIPTION

Stub documentation for DIME, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
