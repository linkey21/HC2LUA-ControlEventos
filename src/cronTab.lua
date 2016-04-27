--[[ TABLA DE ACCIONES (actionTab)
actionTab['nombre'] = {funcion, dispositivos, argumento}
  (string)  funcion: cadena que inidica el nombre de la función fibaro a invocar
  (tabla)   dispositivos: tabla con los dispositivos a los que se aplicará
  (function)  argumento:  función que devuelve el argumento para la función
} --]]
local actionTab = {}

actionTab['enviarPushAlive'] = {
  funcion = 'sendPush',
  dispositivos = {45},
  argumento = function()
    return 'Hola son las '..os.date('%X')..' del '..os.date('%d')..' de '..
    os.date('%B')..' de '..os.date('%Y')..' y sigo vivo'
  end
}

actionTab['diarioPersianas75'] = {
  funcion = 'setValue',
  dispositivos = {65,84,101,103,105,107,109,198,212,235},
  argumento = function() return '75' end
  }

actionTab['diarioPersianaCandela'] = {
  funcion = 'setValue',
  dispositivos = {170},
  argumento = function() return '75' end
  }

actionTab['todasPersianas75'] = {
  funcion = 'setValue',
  dispositivos = {65,84,101,103,105,107,109,170,198,212,235},
  argumento = function() return '75' end
}

actionTab['persianasTemperatura'] = {
  funcion = 'setValue',
  dispositivos = {65,84,103,105,107,109,170,198,212,235},
  argumento = function()
    return tostring(math.floor(100-(fibaro:getValue(34, "value")*2.5)))
  end
} -- la ventana de la terraza donde las planta no se mueve id=101

actionTab['cerrarPersianas'] = {
  funcion='turnOff',
  dispositivos = {65,84,101,103,105,107,109,170,198,212,235},
  argumento = function() return '' end
}

actionTab['apagarLamparitaTerraza'] = {
  funcion='turnOff',
  dispositivos={139},
  argumento = function() return '' end
}
--[[------ FIN TABLA DE ACCIONES ---------------------------------------------]]

--[[ TABLA DE EVENTOS EN EL TIEMPO (ctonTab)
cronTab {type, cronTab, acciones, descripcion}
 (string) type: puede ser 'event' o 'crontab'
   cronTab
     si type == 'event' 	{id=number, min=number}
     si type == 'cronTab'	{min={}, hour={}, day={}, month={}, wday={}}
   (table)  acciones:
   {actionTab['']...} ]]
--[[--------------------------------------------------------------------------]]
local cronTab = {}

-- mensaje de vida
cronTab[#cronTab+1] = {
  type = 'crontab',
  cronTab = {min={00}, hour={12}, day={'*'}, month={'*'}, wday={2,3,4,5,6,7,1}},
  acciones = {actionTab['enviarPushAlive']}
  }

-- días de diario a las 07:45
cronTab[#cronTab+1] = {
  type = 'crontab',
  cronTab = {min={45}, hour={07}, day={'*'}, month={'*'}, wday={2,3,4,5,6}},
  acciones = {actionTab['diarioPersianas75']}
  }

-- días de diario a las 08:10
cronTab[#cronTab+1] = {
  type = 'crontab',
  cronTab = {min={10}, hour={8}, day={'*'}, month={'*'}, wday={2,3,4,5,6}},
  acciones = {actionTab['diarioPersianaCandela']}
  }

-- fines de semana a las 12:00h
cronTab[#cronTab+1] = {
  type = 'crontab',
  cronTab = {min={00}, hour={12}, day={'*'}, month={'*'}, wday={7,1}},
  acciones = {actionTab['todasPersianas75']}
  }

  -- persiana por temperatura finde en primavera('sP') y verano('sU')
cronTab[#cronTab+1] = {
  type = 'crontab',
  cronTab = {min={0}, hour={11,12,13,14,15,16}, day={'sP','sU'},
   month={'sP','sU'}, wday={7,1}},
   acciones = {actionTab['persianasTemperatura']}
  }

-- persiana por temperatura lunes y jueves en primavera('sP') y verano('sU')
cronTab[#cronTab+1] = {
  type = 'crontab',
  cronTab = {min={30}, hour={11,12,13,14}, day={'sP','sU'}, month={'sP','sU'},
    wday={2,5}}, acciones = {actionTab['persianasTemperatura']}
  }

-- persiana por temperatura martes miercoles y viernes en primavera('sP') y
-- en verano('sU')
cronTab[#cronTab+1] = {
  type = 'crontab',
  cronTab = {min={30}, hour={11,12,13,14}, day={'sP','sU'}, month={'sP','sU'},
   wday={3,4,6}}, acciones = {actionTab['persianasTemperatura']}
  }

-- todos los días al anochecer cerrar persianas
cronTab[#cronTab+1] = {
  type = 'crontab',
  cronTab = {min={'sS'}, hour={'sS'}, day={'*'}, month={'*'}, wday={'*'}},
  acciones = {actionTab['cerrarPersianas']}
  }

--[[ 60 min. sin actividad en el dispositivo 154 (Presencia Salón)
cronTab[#cronTab+1] = {
  type = 'event',
  cronTab = {id = 154, min = 60},
  acciones = {actionTab['apagarLamparitaTerraza']}
} --]]
--[[---- FIN TABLA DE EVENTOS ------------------------------------------------]]
