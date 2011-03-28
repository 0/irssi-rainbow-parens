#!/usr/bin/env perl

use strict;
use warnings;

use Irssi;
use Irssi::TextUI;

use List::MoreUtils qw(zip);
use POSIX qw(ceil);

use vars qw($VERSION %IRSSI);
$VERSION = '0.05';
%IRSSI = (
	authors => 'Dmitri Iouchtchenko',
	contact => 'johnnyspoon@gmail.com',
	name => 'rainbow-parens',
	description => 'Displays matching brackets using matching colours.',
	license => 'WTFPL',
);

# What needs balancing?
my %char_pairs = (
	'(' => ')',
	'[' => ']',
	'{' => '}',
);

# All the characters of interest:
my $chars = join('', map { "\\$_" } %char_pairs);
my $chars_regex = qr/
	\G                # From the last match spot,
	(?<text>.*?)      # take anything and then a
	(?<char>[$chars]) # character we want.
/ox;

my @colours = map { "%$_" } qw(b g r m y c);
my $bold_colour = '%9';
my $reset_colour = '%N';
my $error_colour = '%w%1'; # White on red.

# Window management.
my $window_name = $IRSSI{name};
my $min_refnum = 99;
# If the script was restarted, try to find the window it was using.
my $rainbow_window = Irssi::window_find_name($window_name);
my ($min_lines, $max_lines); # From settings.

# Wrap the item in the colour, and embolden.
sub apply_colour {
	my ($colour, $item) = @_;

	return "${bold_colour}${colour}${item}${reset_colour}";
}

# Colourize the brackets in matching pairs.
sub colourize {
	my ($input) = @_;

	# Strings which are separated by the brackets.
	my @resulting_text;
	# Brackets with colour paired, but not yet applied: [colour, character].
	my @resulting_parens;

	# Indices of @resulting_parens.
	my @char_stack;

	# Find all brackets.
	while ($input =~ /$chars_regex/gc) {
		my ($text, $char) = ($+{text}, $+{char});
		my $paren_colour = $error_colour; # Assume the worst.

		if (exists $char_pairs{$char}) { # Opening character.
			# Pick a colour, any colour!
			$paren_colour = $colours[@char_stack % @colours];

			push(@char_stack, scalar @resulting_parens);
		} elsif (@char_stack > 0) { # Closing character?
			if ($char_pairs{$resulting_parens[$char_stack[-1]]->[1]} eq $char) {
				# Use the same colour as the matching item on the stack.
				$paren_colour = $resulting_parens[pop(@char_stack)]->[0];
			} # No match, no pop.
		}

		push(@resulting_text, $text);
		push(@resulting_parens, [$paren_colour, $char]);
	}

	my $final_text; # The remainder of the string.
	if ($input =~ /\G(?<final_text>.*)$/g) {
		$final_text = $+{final_text};
	}

	for my $extra (@char_stack) { # Take care of any leftover brackets.
		$resulting_parens[$extra]->[0] = $error_colour;
	}

	# Apply the final colours and reassemble the string.
	my @coloured_parens = map { apply_colour(@{$_}) } @resulting_parens;
	return join('', zip(@resulting_text, @coloured_parens), $final_text);
}

# Colourize the brackets in the input line and show the results.
sub rainbow_parens {
	return unless $rainbow_window; # Shouldn't happen, really.

	# Get the contents of the input line.
	my $input = Irssi::parse_special('$L');
	$input =~ s/%/%%/g; # Preserve percent signs.

	# Show the result.
	$rainbow_window->command('clear');
	$rainbow_window->print(colourize($input), MSGLEVEL_NEVER);

	# Set window to the appropriate size.
	my $required_lines = ceil(length($input) / $rainbow_window->{width});
	if ($required_lines < $min_lines) {
		$required_lines = $min_lines;
	} elsif ($required_lines > $max_lines) {
		$required_lines = $max_lines;
	}
	if ($rainbow_window->{height} != $required_lines) {
		$rainbow_window->command("window size $required_lines");
	}
}

# Open the preview window.
sub open_window {
	return if $rainbow_window;

	my $lastwin = Irssi::active_win(); # Will need to restore focus later.

	$rainbow_window = Irssi::Windowitem::window_create(0, 0);

	# Claim the name unconditionally; should be unique enough.
	$rainbow_window->set_name($window_name);

	# Ensure we're not treading on anyone for the refnum though.
	my $last_refnum = Irssi::windows_refnum_last();
	if ($last_refnum + 1 >= $min_refnum) { # Big enough.
		$rainbow_window->set_refnum($last_refnum + 1);
	} else {
		$rainbow_window->set_refnum($min_refnum);
	}

	# Show the window, and give back focus.
	$lastwin->set_active();
	$lastwin->command("window show $window_name");
	$lastwin->set_active();

	# Resize later as needed.
	$rainbow_window->command("window size $min_lines");
}

# Close the preview window.
sub close_window {
	return unless $rainbow_window;

	$rainbow_window->destroy();

	$rainbow_window = undef;
}

my $close_on_typing = 0;

# Close the preview window after rainbow_parens_once.
sub close_on_typing {
	if ($close_on_typing) {
		Irssi::signal_remove('gui key pressed' => 'close_on_typing');

		close_window();
	} else {
		# The signal is set up in response to a key press, so skip the first run.
		$close_on_typing = 1;
	}
}

# Toggle temporary, once-view rainbow-parens.
sub rainbow_parens_once {
	return if $rainbow_window; # To do otherwise would be silly.

	open_window();
	rainbow_parens();

	# Prepare the window to be closed upon the next keystroke.
	$close_on_typing = 0;
	Irssi::signal_add_last('gui key pressed' => 'close_on_typing');
}

# Toggle permanent, live-view rainbow-parens.
sub rainbow_parens_toggle {
	if ($rainbow_window) {
		Irssi::signal_remove('gui key pressed' => 'rainbow_parens');

		close_window();
	} else {
		open_window();

		Irssi::signal_add_last('gui key pressed' => 'rainbow_parens');
	}
}

# Try to ensure the setting name is unique.
sub gen_setting_name {
	my ($setting) = @_;

	return "$IRSSI{name}-$setting";
}

# Grab the settings from Irssi.
sub load_settings {
	$min_lines = Irssi::settings_get_int(gen_setting_name('min_lines'));
	$max_lines = Irssi::settings_get_int(gen_setting_name('max_lines'));
}

# Obtain and verify any new settings.
Irssi::signal_add_last('setup changed' => sub {
	load_settings();

	my @problems;

	if ($min_lines <= 1) {
		push @problems, 'min_lines <= 1: Irssi does not appear to support single-line windows.';
	}
	if ($max_lines < $min_lines) {
		push @problems, 'max_lines < min_lines: So confused!';
	}

	if (@problems) {
		print $IRSSI{name}, ' configuration problems:';

		for my $problem (@problems) {
			print ' ' x 4, $problem;
		}
	}
});

Irssi::command_bind('rainbow-parens-once', 'rainbow_parens_once');
Irssi::command_bind('rainbow-parens-toggle', 'rainbow_parens_toggle');

Irssi::settings_add_int($IRSSI{name}, gen_setting_name('min_lines'), 2);
Irssi::settings_add_int($IRSSI{name}, gen_setting_name('max_lines'), 8);

load_settings();
