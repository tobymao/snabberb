// browserify deps.js -p esmify -s snabbdom > opal/vendor/snabbdom.js
import { init } from './node_modules/snabbdom/build/package/init'
import { h } from './node_modules/snabbdom/build/package/h'
import { toVNode } from './node_modules/snabbdom/build/package/tovnode'

import { attributesModule } from './node_modules/snabbdom/build/package/modules/attributes'
import { classModule } from './node_modules/snabbdom/build/package/modules/class'
import { eventListenersModule } from './node_modules/snabbdom/build/package/modules/eventlisteners'
import { propsModule } from './node_modules/snabbdom/build/package/modules/props'
import { styleModule } from './node_modules/snabbdom/build/package/modules/style'

module.exports.init = init
module.exports.h = h
module.exports.toVNode = toVNode

module.exports.attributesModule = attributesModule
module.exports.classModule = classModule
module.exports.eventListenersModule = eventListenersModule
module.exports.propsModule = propsModule
module.exports.styleModule = styleModule
