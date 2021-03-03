// Vendor
require('@rails/ujs').start()

global.Rails = Rails
global.$ = jQuery
global.jQuery = jQuery
global.Blacklight = Blacklight

import '../sentry.js.erb'

// Polyfills for older browers
import 'core-js/stable';
import 'regenerator-runtime/runtime';
import 'whatwg-fetch';
import 'dom4';

import 'bootstrap/dist/js/bootstrap'
import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight'

import 'chosen-js'
import '../blacklight_range_limit/'
import '../articles'
import '../catalog'
import '../advanced_limits_enhanced_ui'
import '../holdings_expandable'
import '../holdings_items'
import '../request_modal'
import '../rmst'
import '../search_type_tab_switch'
import '../toc_shortener'
import '../umlaut_include'

// Our globals

import { has_rmst_cookie, toggle_rmst_cookie } from '../rmst'
global.has_rmst_cookie = has_rmst_cookie
global.toggle_rmst_cookie = toggle_rmst_cookie
