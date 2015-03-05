// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery-ujs
//= require jquery-cookie
//= require jquery-autosize
//= require jquery-ui
//= require reconnectingWebsocket
//= require bootstrap
//= require angular
//= require angular-ui-bootstrap-tpls
//= require select2
//= require angular-ui-select2
//= require codemirror
//= require codemirror/keymaps/emacs
//= require codemirror/keymaps/vim
//= require codemirror/addons/mode/loadmode
//= require codemirror/addons/edit/matchbrackets
//= require turbolinks

//= codemirror_editor
//= angular_app
//= procgarden_controller
//= editor_controller

//= require_tree .

// with turbolinks
$(document).on('ready page:load', function() {
    angular.bootstrap(document.body, ['ProcGardenApp']);
});

// with turbolinks
// for feedback elements
$(document).on('ready page:load', function() {
    $('#feedback-toggle').dropdown();

    $('#feedback-box *').click(function(e) {
        e.stopPropagation();
    });
});
