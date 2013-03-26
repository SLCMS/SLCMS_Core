/*
	jClip jQuery Plugin
	© 2009 ajaxBlender.com
	For any questions please visit www.ajaxblender.com 
	or email us at support@ajaxblender.com
*/

;(function($){
	/*  Variables  */
	$.fn.jclip = function(x, y, w, h){
		var element = $(this);
        
		function _build(){
			if(x == 'remove'){
				if(element.parent().hasClass('__jclip_posobj')){
					element.parent().replaceWith(element);
					if(element.parent().hasClass('__jclip_wrapper')){
                        element.parent().replaceWith(element);						
					}
				}
				return;
			}
			
			if(x == null || y == null){ return; }
			if(w == null || h == null){
				w = x; h = y;
				x = 0; y = 0;
			}

			
			var allowWrapping = (!element.parent().hasClass('__jclip_posobj') || !element.parent().parent().hasClass('__jclip_wrapper'));
			var wrapper = null, posobj = null;
			
			if(allowWrapping){
    			wrapper = $(document.createElement('div'));
    			wrapper.css('overflow', 'hidden').addClass('__jclip_wrapper');
    			
    			posobj = $(document.createElement('div'));
    			posobj.css('position', 'relative').addClass('__jclip_posobj');
			} else {
				posobj = element.parent();
				wrapper = posobj.parent();
			}
			
			wrapper.width(w).height(h).css('position', 'relative');
			posobj.css('left', x * (-1)).css('top', y * (-1));
			
			if(allowWrapping){ element.wrap(wrapper).wrap(posobj); }
		};
		
		//    Entry point
		_build();
	};
})(jQuery);