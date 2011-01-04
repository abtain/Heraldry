var HelpPopup = {}
HelpPopup.Base = Class.create()
HelpPopup.Base.prototype = {
  defaultOptions: {
    position:     '',
    offset:       5,
    topOffset:    0,
    leftOffset:   0,
    duration:     0.4,
    effect:       ['appear', 'appear', 'fade'], // Effect.Toggle, show, hide effects
    text:         'some help'
  },

  initialize: function(anchor, help, options) {
    this.anchor  = anchor
    this.help    = help
    this.options = Object.extend(Object.extend({}, this.defaultOptions), options);
    ['offset', 'topOffset', 'leftOffset'].each(function(p) { this.options[p] = parseInt(this.options[p]); }.bind(this));
    if(!$(this.help)) {
      var help = document.createElement('div')
      this.createTooltip(help)
      document.body.appendChild(help)
      this.setHelpHandlers(help)
    }
    this.toggle();
  },

  toggle: function() {
    Effect.toggle(this.help, this.options.effect[0], {duration:this.options.duration});
  },
  
  show: function() {
    $(this.help).visualEffect(this.options.effect[1], {duration:this.options.duration});
  },

  hide: function() {
    $(this.help).visualEffect(this.options.effect[2], {duration:this.options.duration});
  },

  createTooltip: function(help) {},

  setHelpHandlers: function(help) {
    help.setAttribute('id', this.help);
    Element.setStyle(help, {display:'none'});
    help.className = 'help';
    help.style.position = 'absolute';
    this.setPosition(help);
    
    [this.anchor, help].each(function(e) {
      Event.observe(e, 'mouseover', function() { Element.addClassName(help,    'help_activated'); });
      Event.observe(e, 'mouseout',  function() { Element.removeClassName(help, 'help_activated'); });
    });
  },

  setPosition: function(help) {
    this.an_dimensions = Element.getDimensions(this.anchor);
    this.he_dimensions = Element.getDimensions(help);
    this.dimensions    = this.calculatePosition();
    offsets            = Position.cumulativeOffset(this.anchor);
    help.style.top     = (offsets[1] + this.dimensions.top  + this.options.topOffset)  + 'px';
    help.style.left    = (offsets[0] + this.dimensions.left + this.options.leftOffset) + 'px';
  },

  positionTop: function() {
    return this.positionNegative(this.an_dimensions.height + this.options.offset + this.he_dimensions.height);
  },
  
  positionBottom: function() {
    return (this.an_dimensions.height + this.options.offset);
  },
  
  positionLeft: function() {
    return this.positionNegative(this.options.offset + this.he_dimensions.width);
  },
  
  positionRight: function() {
    return (this.an_dimensions.width + this.options.offset);
  },
  
  positionCenterWidth: function() {
    return this.positionCenter(this.an_dimensions, this.he_dimensions, 'width');
  },
  
  positionCenterHeight: function() {
    return this.positionCenter(this.an_dimensions, this.he_dimensions, 'height')
  },

  positionCenter: function(dimension_1, dimension_2, property) {
    return (dimension_1[property] - dimension_2[property]) / 2;
  },

  positionNegative: function(value) {
    return value - 2 * value;
  },

  calculatePosition: function() {
    var pieces   = this.options.position.split('_');
    var centered = (pieces.length > 1 && pieces[1] == 'centered');
    var pos      = pieces[0];
    switch(pieces[0]) {
      case 'top':    return { top:  this.positionTop(),    left: centered ? this.positionCenterWidth()  : 0 };
      case 'bottom': return { top:  this.positionBottom(), left: centered ? this.positionCenterWidth()  : 0 };
      case 'left':   return { left: this.positionLeft(),   top:  centered ? this.positionCenterHeight() : 0 };
      case 'right':  return { left: this.positionRight(),  top:  centered ? this.positionCenterHeight() : 0 };
    }
    return { left: 0, top: 0 };
  }
}

// provides a basic message and a link to visit more.
HelpPopup.More = Class.create()
HelpPopup.More.prototype = Object.extend(Object.extend({}, HelpPopup.Base.prototype), {
  defaultOptions: Object.extend(Object.extend({}, HelpPopup.Base.prototype.defaultOptions), {
    url:          '#',
    more:         'more info...',
    onBuildClose: function(popup, element) {
      element.innerHTML = "[ <a href=\"#\" onclick=\"new Effect.Fade('" + popup.help + "', {duration:" + popup.options.duration + "})\">close</a> ]";
    }
  }),

  createTooltip: function(help) {
    var more  = document.createElement('a');
    var close = document.createElement('small');
    more.setAttribute('href', this.options.url);
    more.innerHTML  = this.options.more;
    this.options.onBuildClose(this, close)
    
    help.appendChild(document.createTextNode(this.options.text));
    help.appendChild(document.createElement('br'));
    help.appendChild(more);
    help.appendChild(document.createElement('br'));
    help.appendChild(close);
  }
})