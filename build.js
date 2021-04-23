// browserify build.js -p esmify -s snabbdom > opal/vendor/snabbdom.js
import { init } from './node_modules/snabbdom/build/init'
import { h } from './node_modules/snabbdom/build/h'
import { toVNode } from './node_modules/snabbdom/build/tovnode'

import { attributesModule } from './node_modules/snabbdom/build/modules/attributes'
import { classModule } from './node_modules/snabbdom/build/modules/class'
import { datasetModule } from './node_modules/snabbdom/build/modules/dataset'
import { eventListenersModule } from './node_modules/snabbdom/build/modules/eventlisteners'
import { propsModule } from './node_modules/snabbdom/build/modules/props'
import { styleModule } from './node_modules/snabbdom/build/modules/style'

module.exports.init = init
module.exports.h = h
module.exports.toVNode = toVNode

module.exports.attributesModule = attributesModule
module.exports.classModule = classModule
module.exports.datasetModule = datasetModule
module.exports.eventListenersModule = eventListenersModule
module.exports.propsModule = propsModule
module.exports.styleModule = styleModule
