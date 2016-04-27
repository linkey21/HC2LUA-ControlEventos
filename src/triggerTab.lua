--[[ TABLA DE ACCIONES (actionTab)
actionTab['nombre'] = {funcion, dispositivos, argumento}
  (string)  funcion: cadena que inidica el nombre de la función fibaro a invocar
  (tabla)   dispositivos: tabla con los dispositivos a los que se aplicará
  (string)  argumento:  argumento para la función
} --]]
local actionTab = {}

actionTab['enviarPushAgua'] = {
  funcion = 'sendPush',
  dispositivos = {45},
  argumento = 'Se ha cortado el agua'
}

actionTab['cortarLlaveDePaso'] = {
  funcion='turnOn',
  dispositivos={81},
  argumento=''
}

actionTab['enviarPushRestauradoAgua'] = {
  funcion='sendPush',
  dispositivos={45},
  argumento='Se ha restaurado el suministro de agua'
}

actionTab['abrirLlaveDePaso'] = {
  funcion='turnOff',
  dispositivos={81},
  argumento=''
}

actionTab['encenderLamparitaTerraza'] = {
  funcion='turnOn',
  dispositivos={139},
  argumento=''
}

actionTab['apagarLamparitaTerraza'] = {
  funcion='turnOff',
  dispositivos={139},
  argumento=''
}

actionTab['encenderLuzEntrada'] = {
  funcion = 'turnOn',
  dispositivos = {16},
  argumento = ''
}

actionTab['apagaLuzEntrada'] = {
  funcion = 'turnOff',
  dispositivos = {16},
  argumento = ''
}

actionTab['enviarPushPuerta'] = {
  funcion='sendPush',
  dispositivos={45},
  argumento='ALARMA! puerta abierta',
}

actionTab['enviarFotos'] = {
  funcion = 'sendPhotoToUser',
  dispositivos = {17, 176},
  argumento = '2'
}

actionTab['encenderAlarma'] = {
  funcion = 'turnOn',
  dispositivos = {258},
  argumento = ''
}

actionTab['detenerAlarma'] = {
  funcion = 'turnOff',
  dispositivos = {258},
  argumento = ''
}

actionTab['enviarPushUPSOff'] = {
  funcion='sendPush',
  dispositivos={45},
  argumento='El UPS se está descargando, posible fallo eléctrico'
}

actionTab['enviarPushUPSOn'] = {
  funcion = 'sendPush',
  dispositivos ={45},
  argumento='Se ha restaurado la corriente en el UPS'
}

actionTab['enviarPushUPSOn'] = {
  funcion = 'sendPush',
  dispositivos = {45},
  argumento='Se ha restaurado la corriente en el UPS'
}

actionTab['enviarPushUPSBateriaBaja'] = {
  funcion='sendPush',
  dispositivos={45},
  argumento='Batería de UPS por debajo del 50%'
}
--[[------ FIN TABLA DE ACCIONES ---------------------------------------------]]


--[[ TABLA DE EVENTOS POR SUCESO (triggerTab)
  triggerTab {id={}, valor={''}, condicion=function(), retardo=0,
   acciones={actionTab['']} }
--]]
local triggerTab = {}
local trigger = {}

--[[ activado alguno de los detectores de inundación -------------------------]]
triggerTab[#triggerTab+1] = {
  id = {61, 91, 186, 192},
  valor = {'1'},
  condicion = function() return true end,
  retardo = 0,
  acciones = {actionTab["enviarPushAgua"], actionTab["cortarLlaveDePaso"]}
}


--[[ desactivada alarma de sensor de inundación ------------------------------]]
triggerTab[#triggerTab+1] = {
  id = {61, 91, 186, 192},
  valor = {'0'},
  condicion = function() return true end,
  retardo = 0,
  acciones = {actionTab['enviarPushRestauradoAgua'],
   actionTab['abrirLlaveDePaso']}
 }

 --[[ pulsado Enchufe Cafetera en la Cocina -----------------------------------]]
triggerTab[#triggerTab+1] = {
   id = {69},
   valor = {'1','0'},
   condicion = function() return true end,
   retardo = 0,
   acciones = {actionTab['enviarPushRestauradoAgua'],
    actionTab['abrirLlaveDePaso']}
  }

--[[ presencia en el salón detectada es de noche y hace más de 5 minutos que no
ha habido actividad en el salón ----------------------------------------------]]
triggerTab[#triggerTab+1] = {
  id = {154},
  valor = {'1'},
  condicion =
  function()
    if (fibaro:getModificationTime(154, 'value') + 5*60) < os.time() and
     esNoche(os.time()) then return true end
     return false
  end,
  retardo = 0,
  acciones = {actionTab['encenderLamparitaTerraza']}
  }

  --[[ han pasado 15 segundos desde que se ha encendido la lámparita del salón ]]
  triggerTab[#triggerTab+1] = {
    id = {139},
    valor = {'1'},
    condicion =
    function()
       return true
    end,
    retardo = 15,
    acciones = {actionTab['apagarLamparitaTerraza']}
    }

--[[ se abre la puerta de la entrada y es de noche ---------------------------]]
triggerTab[#triggerTab+1] = {
  id = {216},
  valor = {'1'},
  condicion =
  function()
    return esNoche(os.time())
  end,
  retardo = 0,
  acciones={actionTab['encenderLuzEntrada']}
  }

--[[ se cierra la puerta de la entrada y la luz está dada --------------------]]
triggerTab[#triggerTab+1] = {
  id = {216},
  valor = {'0'},
  condicion =
  function()
    return esActivo(16)
  end,
  retardo = 15,
  acciones = {actionTab['apagaLuzEntrada']}
  }

--[[ se abre la puerta y la alarma está armada -------------------------------]]
triggerTab[#triggerTab+1] = {
  id = {261},
  valor = {'1'},
  condicion =
  function()
    return tonumber(fibaro:getValue(261, "armed")) > 0
  end,
  retardo = 2,
  acciones = {actionTab['enviarPushPuerta'], actionTab['enviarFotos']}
  }
  --actionTab['encenderAlarma']
--

--[[ Error en el UPS ---------------------------------------------------------]]
triggerTab[#triggerTab+1] = {
  id = {'upsStatus'},
  valor = {'OB'},
  condicion = function() return true end,
  retardo = 0,
  acciones = {actionTab['enviarPushUPSOff']}
  }

--[[ Recuperación del UPS ----------------------------------------------------]]
triggerTab[#triggerTab+1] = {
  id = {'upsStatus'},
  valor = {'OL'},
  condicion = function() return true end,
  retardo = 0,
  acciones = {actionTab['enviarPushUPSOn']}
  }

--[[ UPS batería baja --------------------------------------------------------]]
triggerTab[#triggerTab+1] = {
  id = {'upsStatus'},
  valor = {'LB'},
  condicion = function() return true end,
  retardo = 0,
  acciones = {actionTab['enviarPushUPSBateriaBaja']}
  }
--[[---- FIN TABLA DE EVENTOS ------------------------------------------------]]
