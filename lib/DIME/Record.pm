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

package DIME::Record;

use 5.008;
use strict;
use warnings;

use Data::UUID;

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


# Preloaded methods go here.

my $DIME_VERSION = 1;

sub new
{
	my $class = shift;	
	my $payload = shift;
	my $this = {
			_VERSION => $DIME_VERSION,
			_MB => 0,
			_ME => 0,
			_CF => 0,
			_ID_LENGTH => 0,
			_TNF => 0x03,
			_TYPE_LENGTH => 0,
			_DATA_LENGTH => 0,
			_OPTIONS => 0,
			_OPTIONS_LENGTH => 0,
			_ID => undef,
			_TYPE => undef,
			_DATA => undef,
			_BUFFER_SIZE => 1024,
		};
	my $self = bless $this, $class;
	if(defined($payload))
	{
		$self = bless $this,$class;
		$self->id($payload->id());
		$self->type($payload->type());
		$self->tnf($payload->tnf());
		$self->{_BUFFER_SIZE} = $payload->{_BUFFER_SIZE};
	}
	return $self;
}

sub DESTROY
{
	my $self = shift;
	$self->{_DATA}->close() if($self->{_DATA});
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


sub cf
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_CF} = $param;
        }
        else
        {
                return $self->{_CF};
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

sub chunked
{
	my $self = shift;
	my $chunked = shift;
	$self->{_CF} = $chunked;
}

sub set_unchanged_type
{
	my $self = shift;
	$self->{_TNF} = 0;
	$self->{_TYPE_LENGTH} = 0;
}

# Read from a IO::Handle a DIME record
sub read
{
	my $self = shift;
	my $in = shift;
	
	my $buf;
	my $padding;
	my $offset = 0;		
	$in->read($buf,4);	
	my $dword = unpack "N",$buf;
	$offset+=4;
	$self->{_VERSION} = $dword >> 27;
	$self->{_MB} = ($dword >> 26) & 0x1;
	$self->{_ME} = ($dword >> 25) & 0x1;
	$self->{_CF} = ($dword >> 24) & 0x1;
	$self->{_TNF} = ($dword >> 20) & 0xF;
	$self->{_OPTIONS} = ($dword >> 16 ) & 0xF;
	$self->{_OPTIONS_LENGTH}= $dword & 0xFFFF;
	
	$in->read($buf,4);	
	$dword = unpack "N",$buf;
	$offset+=4;

	$self->{_ID_LENGTH} = $dword >> 16;
	$self->{_TYPE_LENGTH} = $dword & 0xFFFF;

	$in->read($buf,4);
	$self->{_DATA_LENGTH} = unpack "N",$buf;
	$offset+=4;
	
	if($self->{_ID_LENGTH}>0)
	{		
		my $id;
		$in->read($id,$self->{_ID_LENGTH});
		$self->{_ID}= $id;
		$offset += $self->{_ID_LENGTH};	
		if($self->{_ID_LENGTH} % 4)
		{
			$padding = 4-($self->{_ID_LENGTH} % 4);	
			$in->read($buf,$padding);
			$offset += $padding;
		}
		
	}	
	if($self->{_TYPE_LENGTH}>0)
	{
		my $type;		
		$in->read($type,$self->{_TYPE_LENGTH});
		$self->{_TYPE} = $type;
		$offset += $self->{_TYPE_LENGTH};
		if($self->{_TYPE_LENGTH} % 4)
		{
			$padding = 4-($self->{_TYPE_LENGTH} % 4);
			$in->read($buf,$padding);
			$offset += $padding;
		}
		
		
	}		
	if($self->{_DATA_LENGTH}>0)
	{
		my $data;
		$in->read($data,$self->{_DATA_LENGTH});
		$self->{_DATA} = new IO::Scalar \$data;
		$offset += $self->{_DATA_LENGTH};
		if($self->{_DATA_LENGTH} % 4)
		{
			$padding = 4-($self->{_DATA_LENGTH} % 4);
			$in->read($buf,$padding);
			$offset += $padding;
		}
	}		
	return $offset;
}

sub print
{
	my $self = shift;
	my $out = shift;

	# Read the data from the stream
	my $read_bytes;
	my $total_bytes=0;
	my $total_buf;
	my $buf;
	if($self->{_CHUNK_SIZE})
	{
		while(!$self->{_DATA}->eof() and $total_bytes < $self->{_CHUNK_SIZE})
		{
			$read_bytes = $self->{_DATA}->read($buf,$self->{_CHUNK_SIZE}-$total_bytes);
			$total_buf .= $buf;
			$total_bytes += $read_bytes;
		}
	}
	else
	{
		while(!$self->{_DATA}->eof())
		{
			$read_bytes = $self->{_DATA}->read($buf,$self->{_BUFFER_SIZE});
			$total_buf .= $buf;
			$total_bytes += $read_bytes;
		}
	}

	$self->{_DATA_LENGTH} = $total_bytes;	

	my $dword = ($self->{_VERSION} << 27)| ($self->{_MB} << 26 )| ($self->{_ME} << 25) | ($self->{_CF} << 24) | ($self->{_TNF} << 20) | ($self->{_OPTIONS} << 16) | $self->{_OPTIONS_LENGTH};
	$out->print(pack("N",$dword));

	# bit
	# 32...                |48...
	# --------------------------------------
	# ID_Length            | Type_Length	
	
	$dword = ($self->{_ID_LENGTH} << 16)| $self->{_TYPE_LENGTH};
	$out->print(pack ("N",$dword));

	# Add to the record the length of the data	

	$dword = $self->{_DATA_LENGTH};
	$out->print(pack ("N",$dword));
	
	# and the ID plus padding (mult. 4 bytes)
	if($self->{_ID_LENGTH}>0)
	{
		$out->print($self->{_ID});
		# padding
		if($self->{_ID_LENGTH} % 4)
		{
			for(my $i=(4-($self->{_ID_LENGTH} %4));$i>0;$i--)
			{
				$out->print(chr(0));
			}
		}
	}

	# we do the same with the type
	if($self->{_TYPE_LENGTH}>0)
	{
		$out->print($self->{_TYPE});
		# padding
		if($self->{_TYPE_LENGTH} % 4)
		{
			for(my $i=(4-($self->{_TYPE_LENGTH} %4));$i>0;$i--)
			{
				$out->print(chr(0));
			}
		}
	}

	if($self->{_DATA_LENGTH}>0)
	{
		$out->print($total_buf);	
		# padding
		if($self->{_DATA_LENGTH} % 4)
		{
			for(my $i=(4-($self->{_DATA_LENGTH} %4));$i>0;$i--)
			{
				$out->print(chr(0));
			}
		}
	}

}
sub type
{
	my $self = shift;
	my $param = shift;
	if(defined($param))
	{
		$self->{_TYPE} = $param;
		$self->{_TYPE_LENGTH} = length($param);
	}
	else
	{
		return $self->{_TYPE};
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
		$self->{_ID_LENGTH} = length($param);
		$self->{_ID} = $param;
	}
	else
	{
		return $self->{_ID};
	}
}


# Set/return the IO::Handle to access the data
sub data
{
	my $self = shift;
	my $param = shift;
	if(defined($param))
	{
		$self->{_DATA} = $param;
	}
	else
	{
		return $self->{_DATA};
	}
}

sub print_content
{
	my $self = shift;
	my $out = shift;
	#$self->{_DATA}->seek(0,0);
	my $buf;
	while(!$self->{_DATA}->eof())
	{
		$self->{_DATA}->read($buf,$self->{_BUFFER_SIZE});
		$out->print($buf);
	}
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
