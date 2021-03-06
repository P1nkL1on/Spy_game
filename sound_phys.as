﻿class sound_phys {
	static var defaultFolder:String = "sounds/";
	
	static var sound_names:Array = new Array();
	static var sound_rads:Array = new Array();
	static var sounds:Array = new Array();
	//static var sound_reserves:Array = new Array();
	
	static var sound_speed:Number = 33; // 33
	
	static function initialise (){
		push ("gun_get", 70);
		push ("gun_shoot", 150, 35);
		push ("gun_reload", 80);
		push ("gun_no_ammo", 120, 250);
		push ("ttgun_shoot", 500, 60);
		push ("ttgun_reload", 90);
		push ("body_shot", 200, 500);
		push ("head_shot", 230, 500);
		push ("shelm_shot", 300, 500);
		push ("jacket_shot", 120, 500);
		push ("ground_shot", 150, 100);
		push ("ground_default", 50, 100);
		push ("step_default", 40, 50);
	}
	static function push (nam:String, rad:Number, frequency:Number){
		if (frequency == undefined) frequency = 100;
		sound_names.push(nam); sound_rads.push(rad);
		sounds.push(new Array()); sounds[sounds.length - 1].push(new Sound());
		sounds[sounds.length - 1][0].ind = sounds.length - 1; 
		sounds[sounds.length - 1][0].loadSound(defaultFolder + nam + '.mp3'); sounds[sounds.length - 1][0].name = nam; sounds[sounds.length - 1][0].path = defaultFolder + nam + '.mp3';
		sounds[sounds.length - 1][0].fr = frequency;
		sounds[sounds.length - 1][0].onLoad = function(success:Boolean):Void 
			{ if (success){ 
				
				if (this.fr == -1) 
					this.fr = this.duration; // no need to load more
				else
					{ var much:Number = Math.max(1, Math.round(this.duration / this.fr)); 
					  for (var i = 0; i < much; i++){ sounds[this.ind].push(new Sound());		// load reserve copyes
														   sounds[this.ind][sounds[this.ind].length - 1].loadSound(this.path); 
														   sounds[this.ind][sounds[this.ind].length - 1].path = sounds[this.ind][0].path; 
														   sounds[this.ind][sounds[this.ind].length - 1].name = sounds[this.ind][0].name;   
														  }}
			}
			trace ("sounds/" + nam + "\t\t"+this.duration+"\t\t✔\t" + ((this.much == undefined)? 0 : this.much)); 
			}
	}
	
	static var ts:Number = 0;
	static function sound (what:String, sourse, s_x_offset, s_y_offset, rad){
		if (what == 'step' || what == 'ground')
			what += '_default';
		
		var get_rad:Number = undefined; var numer:Number = -1;
		for (var i = 0; i < sound_names.length; i++) if ( sound_names[i] == what ){ get_rad = sound_rads[i]; numer = i;}
		if (rad != undefined)get_rad = rad;
		if (get_rad == undefined){ trace ('No match for sound ' + what); return; }
		
		ts++;
		_root.attachMovie("sound_circle", "sc_" + ts, _root.getNextHighestDepth()); var ss:MovieClip = _root["sc_" + ts];
		ss._x = sourse._x + ((s_x_offset == undefined)? 0 : s_x_offset ); ss._y = sourse._y + ((s_y_offset == undefined)? 0 : s_y_offset) ;
		
		ss.max_rad = get_rad * 1.5;
 		ss.current_rad = 0; ss.rad._width = ss.max_rad * 2; ss.rad._height = ss.max_rad * 2; 	ss.wave._width = 0; ss.wave._height = 0; 
		ss.snd_name = what;   //ss._visible = false;
		ss.onEnterFrame = function (){
			this._visible = (Key.isDown(Key.SPACE));
			this.current_rad = Math.min( this.max_rad, this.current_rad + sound_speed * _root.time_passed );
			this.wave._width = this.current_rad * 2; this.wave._height = this.current_rad * 2;  this._alpha = 100 * (1 - this.current_rad / this.max_rad);
			if (this.current_rad >= this.max_rad) this.removeMovieClip();
		}
		if (numer > -1){
			for (var i = 0; i< _root.hitable.length; i++) if (_root.hitable[i].pater.can_listen){
				var who:MovieClip = _root.hitable[i].pater;
				var dist:Number = Math.sqrt( Math.pow(ss._x - who._x, 2) + Math.pow(ss._y - who._y,2));
				var max_dist:Number = ss.max_rad * 1;
				if (dist < max_dist){
					who.sound_numer.push( numer );
					who.sound_timer.push(dist / sound_speed);
					who.sound_volume.push(Math.max(0, 100 - 100 * (Math.exp(-Math.max((max_dist - dist), 0) / (max_dist / 4)))));
				}//Math.max(0, 100 * (max_dist - dist) / max_dist));}		
			}
		}
	}
	static function set_volume_listener (who:MovieClip){
		who.can_listen = true;
		who.sound_timer = new Array();
		who.sound_numer = new Array();
		who.sound_volume = new Array();
		who.heard_sounds = new Array(); who.heard_sounds_volume = new Array();
	}
	static function play_sound (numer:Number, volum:Number):Number{
		for (var i = 0; i < sounds[numer].length; i++)
			if ( sounds[numer][i].position <= 0 || sounds[numer][i].position >= sounds[numer][i].duration )
				{sounds[numer][i].setVolume(volum); sounds[numer][i].start(0,1); return i;}
		return -1;
	}
	static function check_listen_sound (who:MovieClip){
		for (var i =0; i < who.sound_timer.length; i++){
			who.sound_timer[i]-= _root.time_passed;
			if (who.sound_timer[i] <= 0)
			{ sounds[who.sound_numer[i]].setVolume(who.sound_volume[i]); 
			  who.heard_sounds.push(sounds[who.sound_numer[i]][0].name); 
			  who.heard_sounds_volume.push(Math.round(who.sound_volume[i]*10)/10); 
			  if (who.heard_sounds.length > 100){ who.heard_sounds.splice(0,1);  who.heard_volume.splice(0,1);}
			  if (who == _root.hero) {
				  if (play_sound (who.sound_numer[i], who.sound_volume[i]) == -1) trace ('not enought sound copys');
			  }
			  i --;
			  for (var j = i; j < who.sound_timer.length - 1; j++){ who.sound_timer[j] = who.sound_timer[j+1]; 
			  														who.sound_numer[j] = who.sound_numer[j+1];
																	who.sound_volume[j] = who.sound_volume[j+1]; } who.sound_timer.pop(); who.sound_numer.pop(); who.sound_volume.pop();}
		}
	}
	
}