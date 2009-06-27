Settings = imports.Settings;
GLib = imports.gi.GLib;
Clutter = imports.gi.Clutter;
LED = imports.LED;
Board = imports.Board;
Arrow = imports.Arrow;

var last_direction, last_sign;

GameView = new GType({
	parent: Clutter.Group.type,
	name: "GameView",
	init: function()
	{
		// Private
		var self = this;
		var current_level = 1;
		var score_view = new LED.LEDView();
		var board_view = new Board.BoardView();
		var backing_view = new Clutter.Clone({source:Settings.theme.backing});
		var left_arrow = new Arrow.ArrowView();
		var right_arrow = new Arrow.ArrowView();
		var new_board_view = null;
		var timeline;
		
		// Set up a new board.
		var create_next_board = function()
		{
			new_board_view = new Board.BoardView();
			new_board_view.load_level(current_level);
			new_board_view.signal.game_won.connect(game_won);
			new_board_view.hide();
			new_board_view.set_playable(false);
			self.add_actor(new_board_view);
			new_board_view.lower_bottom();
		}
		
		// The boards have finished transitioning; delete the old one!
		var board_transition_complete = function()
		{
			self.remove_actor(board_view);
			board_view = new_board_view;
			board_view.set_playable(true);
			timeline = 0;
		}
		
		// The player won the game; create a new board, update the level count,
		// and transition between the two boards in a random direction.
		var game_won = function()
		{
			if(timeline && timeline.is_playing())
				return false;
			
			var direction, sign;
			score_view.set_value(++current_level);
			
			// Make sure the board transition is different than the previous.
			do
			{
				direction = Math.floor(2 * Math.random());
				sign = Math.floor(2 * Math.random()) ? 1 : -1;
			}
			while(last_direction == direction && last_sign != sign);
	
			last_direction = direction;
			last_sign = sign;
			
			timeline = new Clutter.Timeline({duration: 1500});
			
			create_next_board();
			new_board_view.show();
			
			new_board_view.animate_in(direction, sign, timeline);
			board_view.animate_out(direction, sign, timeline);
			timeline.signal.completed.connect(board_transition_complete);
				
			return false;
		}
		
		var swap_board = function(arrow, event, context)
		{
			if(timeline && timeline.is_playing())
				return false;
			
			current_level += context.direction;
			
			if(current_level <= 0)
			{
				current_level = 1;
				return false;
			}
			
			score_view.set_value(current_level);
			
			timeline = new Clutter.Timeline({duration: 500});
			
			create_next_board();
			
			new_board_view.depth = context.direction * -250;
			new_board_view.opacity = 0;
			
			new_board_view.show();
			
			new_board_view.swap_in(context.direction, timeline);
			board_view.swap_out(context.direction, timeline);
			timeline.signal.completed.connect(board_transition_complete);
			
			timeline.start();
			
			return false;
		}
		
		var theme_changed = function()
		{
			// TODO: only animate if theme changes!
			timeline = new Clutter.Timeline({duration: 1500});
			
			create_next_board();
			new_board_view.opacity = 0;
			new_board_view.show();
			
			board_view.fade_out(timeline);
			new_board_view.fade_in(timeline);
			new_board_view.raise_top();
			
			timeline.signal.completed.connect(board_transition_complete);
			timeline.start();
		}
		
		// Public
		
		this.reset_game = function ()
		{
			if(timeline && timeline.is_playing())
				return false;

			current_level = 1;
			
			score_view.set_value(current_level);
			
			timeline = new Clutter.Timeline({duration: 500});
			
			create_next_board();
			
			new_board_view.depth = 250;
			new_board_view.opacity = 0;
			
			new_board_view.show();
			
			new_board_view.swap_in(-1, timeline);
			board_view.swap_out(-1, timeline);
			timeline.signal.completed.connect(board_transition_complete);
			
			timeline.start();
			
			return false;
		}
		
		// Implementation
		
		// TODO: wrong::
		
		current_level = Settings.score;
		Seed.print(current_level);
		
		// Set up and show the initial board
		board_view.signal.game_won.connect(game_won);
		board_view.load_level(current_level);
		this.add_actor(board_view);
		create_next_board();
		
		backing_view.set_position(0, board_view.height);
		this.add_actor(backing_view);
		
		score_view.set_anchor_point(score_view.width / 2, 0);
		score_view.set_position(board_view.width / 2, board_view.height + 18);
		this.add_actor(score_view);
		
		left_arrow.set_position((score_view.x - score_view.anchor_x) / 2,
		                        score_view.y + (score_view.height / 2));
		this.add_actor(left_arrow);
		
		right_arrow.flip_arrow();
		right_arrow.set_position(board_view.width - left_arrow.x,
		                         score_view.y + (score_view.height / 2));
		this.add_actor(right_arrow);
		
		left_arrow.signal.button_release_event.connect(swap_board, {direction: -1});
		right_arrow.signal.button_release_event.connect(swap_board, {direction: 1});
		
		score_view.set_width(5);
		score_view.set_value(current_level);
		
		this.set_size(board_view.width, score_view.y + score_view.height);

		Settings.Watcher.signal.theme_changed.connect(theme_changed);
	}
});

