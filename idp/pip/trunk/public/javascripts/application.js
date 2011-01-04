/* Licensed to the Apache Software Foundation (ASF) under one
   or more contributor license agreements.  See the NOTICE file
   distributed with this work for additional information
   regarding copyright ownership.  The ASF licenses this file
   to you under the Apache License, Version 2.0 (the
   "License"); you may not use this file except in compliance
   with the License.  You may obtain a copy of the License at
 
     http://www.apache.org/licenses/LICENSE-2.0
 
   Unless required by applicable law or agreed to in writing,
   software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
   KIND, either express or implied.  See the License for the
   specific language governing permissions and limitations
   under the License. */

HelpPopup.Login = Class.create()
HelpPopup.Login.prototype = Object.extend(Object.extend({}, HelpPopup.Base.prototype), {
  createTooltip: function(help) {
    help.innerHTML = "  <div id=\"login-title\">login</div>\n" +
      "  <div id=\"login-close\"><a href=\"#\" onclick=\"toggleLoginForm(this); return false;\"><img src=\"/images/loginbox/x.gif\" alt=\"close\" width=\"18\" height=\"18\" /></a></div>\n" +
      "  <div id=\"login-form\">\n" +
      "    <form id=\"hovering-login\" method=\"post\" action=\"" + 
      $('protocol').innerHTML + "://" + $('domain').innerHTML + "/account/login\">\n" +
      "      <input type=\"hidden\" name=\"session_id_validation\" value=\"" + $('session-id-validation').innerHTML + "\" />\n" +
      "      <label for=\"login_username\">User ID</label>\n" +
      "      <input type=\"text\" id=\"login_username\" name=\"login\" value=\"\" class=\"input\" /><br />\n" +

      "      <label for=\"login_password\">Password</label>\n" +
      "      <input type=\"password\" id=\"login_password\" name=\"password\" value=\"\" class=\"input\" /><br />\n" +

      "      <input type=\"image\" class=\"submit\" value=\"Login\" src=\"/images/buttons/login.gif\" alt=\"Login\" />\n" +
      "    </form>\n" +
      "  </div>\n" +
      "  <a href=\"/account/forgot_password\" id=\"login-forgot\">Forgot your password? &gt;&gt;</a>\n" +
      "  <div id=\"login-roundbottomleft\"><img src=\"/images/loginbox/botleft.gif\" width=\"22\" height=\"19\" alt=\"\" /></div>\n" +
      "  <div id=\"login-roundbottomright\"><img src=\"/images/loginbox/botright.gif\" width=\"22\" height=\"19\" alt=\"\" /></div>\n";
  },

  initialize: function(anchor, help, options) {
    this.anchor  = anchor
    this.help    = help
    this.options = Object.extend(Object.extend({}, this.defaultOptions), options);
    ['offset', 'topOffset', 'leftOffset'].each(function(p) { this.options[p] = parseInt(this.options[p]); }.bind(this));
    if(!$(this.help)) {
      var help = $('header-loginlock');
      this.createTooltip(help)
      this.setHelpHandlers(help)
    }
    this.toggle();
  },

  setPosition: function(help) {
    help.style.top     = '0px'; //=(offsets[1] + this.dimensions.top  + this.options.topOffset)  + 'px';
    help.style.left    = '550px';//(offsets[0] + this.dimensions.left + this.options.leftOffset) + 'px';
    help.style.zIndex  = '25';
  }
})

HelpPopup.Tooltip = Class.create()
HelpPopup.Tooltip.prototype = Object.extend(Object.extend({}, HelpPopup.Base.prototype), {
  defaultOptions: Object.extend(Object.extend({}, HelpPopup.Base.prototype.defaultOptions), {
    url:          '#',
    more:         'more...'
  }),
  
  createTooltip: function(help) {
    help.innerHTML = "" +
    "<div class=\"rbroundbox\">\n" +
    "  <div class=\"rbtop\"><div></div></div>\n" +
    "  <div class=\"rbcontent\">\n" +
    this.options.text + "\n" +
    "  </div>\n" +
    "  <div class=\"rbbot\"><div></div></div>\n" +
    "</div>\n";
  }
})

HelpPopup.Tooltip.all = {};
HelpPopup.Tooltip.show = function(anchor) {
  if(!HelpPopup.Tooltip.all['rbox-' + anchor.id]) {
    title = anchor.title;
    anchor.title = '';
    HelpPopup.Tooltip.all['rbox-' + anchor.id] = new HelpPopup.Tooltip(anchor, 'rbox-' + anchor.id, {position: 'bottom', topOffset: '10px;', text: title, duration: 0 });
  } else {
    HelpPopup.Tooltip.all['rbox-' + anchor.id].show();
  }
};

HelpPopup.Tooltip.add = function(anchor) {
  if(!HelpPopup.Tooltip.all['rbox-' + anchor.id]) {
    title = anchor.title;
    anchor.title = '';
    HelpPopup.Tooltip.all['rbox-' + anchor.id] = new HelpPopup.Tooltip(anchor, 'rbox-' + anchor.id, {position: 'bottom', topOffset: '10px;', text: title, duration: 0 });
  } else {
    HelpPopup.Tooltip.all['rbox-' + anchor.id].show();
  }
  
};

HelpPopup.Tooltip.hide = function(anchor) {
  HelpPopup.Tooltip.all['rbox-' + anchor.id].hide();
};

HelpPopup.Tooltip.init = function() {
  document.getElementsByClassName('tooltip').each(function(tooltip) {
    tooltip.onmouseover = function() {
      HelpPopup.Tooltip.show(tooltip);
      return false;
    };
    
    tooltip.onmouseout = function() {
      HelpPopup.Tooltip.hide(tooltip);
      return false;
    };
  });
};

var toggleTooltip = HelpPopup.Tooltip.toggle;

function toggleLoginForm(anchor) {
  new HelpPopup.Login(anchor, 'login', {});
}

var CategoryForm = {
  options: { duration: 0.6, activeClass: 'profile-enabled', inactiveClass: 'profile-disabled' },

  set_ids: function(id) {
    this.id = id;
    this.category_id = 'category_content_' + id;
    this.toggle_id = 'toggle_' + id;
  },
  
  check_states: function() {
    this.expanded =  Element.Methods.visible(this.category_id);
    this.active =    $(this.category_id).hasClassName(this.options.activeClass);
  },
  
  expand: function() {
    $(this.category_id).visualEffect('blind_down', this.options);
    $(this.toggle_id).src = '/images/buttons/contract_off.gif';
  },
  
  collapse: function() {
    $(this.category_id).visualEffect('blind_up', this.options);
    $(this.toggle_id).src = '/images/buttons/expand_off.gif';
  },
  
  update: function(id) {
    this.set_ids(id);
    this.check_states();
    
    this.deactivate(this.id);
    $(this.category_id).visualEffect('highlight', { duration: 0.4, queue: 'front' });
  },
  
  deactivate: function(id) {
    this.set_ids(id);
    this.check_states();

    Element.childrenWithClassName(this.category_id,'edit-element').each(function(tr) {
      $(tr).visualEffect('fade');      
    });

    $('edit_icon_'+this.id).visualEffect('fade');

    if($('category_title_'+this.id)) {
      $('category_title_'+this.id).removeClassName(this.options.activeClass);
      $('delete_icon_'+this.id).visualEffect('fade');
    }
    $('category_save_'+this.id).hide();
    $(this.category_id).removeClassName(this.options.activeClass);
  },
  
  activate: function(id) {
    this.set_ids(id);
    this.check_states();
    //alert('activate: '+ this.id);
    Element.childrenWithClassName(this.category_id,'edit-element').each(function(tr) {
      $(tr).visualEffect('appear');
    });
    $('edit_icon_'+this.id).visualEffect('appear');
    // if the category is editable
    if($('category_title_'+this.id)) {
      $('category_title_'+this.id).addClassName(this.options.activeClass);
      $('delete_icon_'+this.id).visualEffect('appear');
    }
    $('category_save_'+this.id).show();
    $(this.category_id).removeClassName(this.options.inactiveClass);
    $(this.category_id).addClassName(this.options.activeClass);
  },
  
  toggle_collapse: function(id) {
    this.set_ids(id);
    this.check_states();
    
    if(this.expanded) {
      this.collapse();
    } else {
      this.expand();
      $(this.category_id).removeClassName('killjoy');
    }
  },
  
  toggle_collapse_and_activation: function(id) {
    this.set_ids(id);
    this.check_states();
    
    // collapsed or expanded?
    if(this.expanded) {
      if(this.active) {
        // if(expanded and active), collapse and deactivate
        this.deactivate(this.id);
      }
      this.collapse();
      $(this.category_id).addClassName('killjoy');
    } else {
      if(!this.active) {
        // if(collapsed and active), expand and activate
        this.activate(this.id);
      }
      this.expand();
    }
  },
  
  toggle_activation: function(id) {
    this.set_ids(id);
    this.check_states();

    if(!this.expanded) {
      this.expand();
    }

    if(this.active) {
      this.deactivate(this.id);
    } else {
      this.activate(this.id);
    }
  },
  
  activate_section: function(id) {
    this.set_ids(id);
    this.check_states();

    if(this.expanded && !this.active && !$(this.category_id).hasClassName('killjoy')) {
      this.activate(this.id);
    }

  },
  
  observe_fields: function(id) {
    this.set_ids(id);
    this.check_states();
    var i = 0;
    Element.childrenWithClassName(this.category_id,'profile-field').each(function(el) {
      Event.observe(el, 'click', function(event) { CategoryForm.toggle_activation(id); } );
    });
  }
};

var TrustProfileForm = {
  highlight_profile: function() {
    var element = $('trust_profile');
    var selected_profile = element.options[element.selectedIndex].value;
    
    // remove class names
    $$('#requested_properties tr input').each(function(tr) {
      if(selected_profile == '-1') {
        $(tr).disabled = false;
      } else {
        $(tr).disabled = true;
      }
      $(tr).checked = false;
    });
    
    if(selected_profile == '-1') {
      $('trust-profile-name').disabled = false;
    } else {
      $('trust-profile-name').disabled = true;
    }
    
    if($('profile_'+ selected_profile + '_properties')) {
      var profile_properties = $('profile_'+ selected_profile + '_properties').value.split(',');

      profile_properties.each(function(property) {
        if($('property-'+ property)) {
          $('property-'+ property).checked = true;
        }
      });
    }
  }
};

var DataTable = {
  colorizeRow: function(id) {
    var profile  = $(id);
    var previous = profile.getPreviousSibling('tr');
    if((previous) && (previous.className == 'even')) {
      profile.removeClassName('even');
      profile.addClassName('odd');
    }
  },

  colorizeRows: function(table_id) {
    var i = 0;
    $$('#' + table_id + ' tbody tr').each(function(tr) {
      if(Element.Methods.visible(tr)) {
        tr.className = (i % 2 == 0) ? 'even' : 'odd';
        i++;
      }
    });
  }
};

Element.Methods.getPreviousSibling = function(element, element_name) {
  var ps = element.previousSibling;
  if(!ps) {
    return null;
  } else if((ps.nodeName) && (ps.nodeName.toLowerCase() == element_name.toLowerCase())) {
    return ps;
  } else {
    return Element.Methods.getPreviousSibling(ps, element_name);
  }
}

Event.observe(window, 'load', HelpPopup.Tooltip.init);
