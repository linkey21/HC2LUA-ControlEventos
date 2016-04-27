--[[
%% autostart
--]]

--[[ Control de Eventos
	escena
	runCronTab.lua
	por Manuel Pascual
------------------------------------------------------------------------------]]

--[[----- CONFIGURACION DE USUARIO -------------------------------------------]]
--[[ TABLA DE ACCIONES (actionTab)
actionTab['nombre'] = {funcion, dispositivos, argumento}
  (string)  funcion: cadena que inidica el nombre de la función fibaro a invocar
  (tabla)   dispositivos: tabla con los dispositivos a los que se aplicará
  (function)  argumento:  función que devuelve el argumento para la función
}
--------- PONGA A CONTINUACION LA DECRARACIÓN DE ACCIONES --------------------]]

--[[----- FIN TABLA DE ACCIONES ----------------------------------------------]]

--[[ TABLA DE EVENTOS EN EL TIEMPO (ctonTab)
cronTab {type, cronTab, acciones, descripcion}
 (string) type: puede ser 'event' o 'crontab'
   cronTab
     si type == 'event' 	{id=number, min=number}
     si type == 'cronTab'	{min={}, hour={}, day={}, month={}, wday={}}
   (table)  acciones:
   {actionTab['']...}
--------- PONGA A CONTINUACION LA DECRARACIÓN DE EVENTOS ---------------------]]

--[[---- FIN TABLA DE EVENTOS ------------------------------------------------]]
--[[----- FIN CONFIGURACION DE USUARIO ---------------------------------------]]
--[[----- NO CAMBIAR EL CODIGO A PARTIR DE AQUI ------------------------------]]


--[[----- CONFIGURACION AVANZADA ---------------------------------------------]]
OFF=1;ERROR=2;INFO=3;DEBUG=4  -- referencia para el log
nivelLog = INFO               -- nivel de log
--[[----- FIN CONFIGURACION AVANZADA -----------------------------------------]]

--[[toolKit
Conjunto de funciones para compartir en varios proyectos --]]
if not toolKit then toolKit = {
  __version = "1.0.1",
  -- log(level, log)
  -- (global) level: nivel de LOG
  -- (string) mensaje: mensaje
  log = (
  function(self, level, mensaje, ...)
    if not mensaje then mensaje = 'nil' end
    if nivelLog >= level then
      local color = 'yellow'
      if level == INFO then color = 'green' end
      if level == ERROR then color = 'red' end
      fibaro:debug(string.format(
      '<%s style="color:%s;">%s</%s>', "span", color, mensaje, "span")
      )
    end
  end)
} end

--[[ eventToCronTab(evento)
  (table) evento: tabla que representa un evento
  Convertir un evento en un cronTab --]]
function eventToCronTab (evento)
  local valor, timeStamp = fibaro:get(evento.id, 'value')
  timeStamp = timeStamp + evento.min * 60

  local cronTab={
    min		= {tonumber(os.date("%M", timeStamp))},
    hour	= {tonumber(os.date("%H", timeStamp))},
    day		= {tonumber(os.date("%d", timeStamp))},
    month	= {tonumber(os.date("%m", timeStamp))},
    wday	= {tonumber(os.date("%w", timeStamp))+1}
  }
  return cronTab
end

--[[estacion(instante)
  (timeStamp) instante: timestamp de un momento dado
  Averiguar la estación del año de un momento dado --]]
function estacion(instante)
  local miInstante = os.date("*t",instante)
  -- equinoccio de primavera 21 marzo
  miInstante.month = 3; miInstante.day = 21
  local eqPrimavera = os.time(miInstante)
  --  solsticio de verano 21 de junio
  miInstante.month = 6; miInstante.day = 21
  local slVerano = os.time(miInstante)
  -- equinoccio de otoño 23 de septiembre
  miInstante.month = 9; miInstante.day = 23
  local eqOtonno = os.time(miInstante)
  -- solsticio de invierno  21 de diciembre
  miInstante.month = 12; miInstante.day = 21
  local slInvierno = os.time(miInstante)
  --
  if (instante >= slInvierno) then return 'wI'
  elseif(instante >= eqOtonno) then return 'aU'
  elseif(instante >= slVerano) then return 'sU'
  elseif(instante > eqPrimavera) then return 'sP'
  else return 'wI' end
end

--[[inTable(tbl, item)
  (tabla) tbl:    tabla en la que buscar un item
  (object) item:  item a buscar en la tabla
  Devuelve si un item pertenece a la tabla --]]
function inTable(tbl, item)
  for key, value in pairs(tbl) do
    if value == '*' or value == item then
      return true
    end
  end
  return false
end

--[[esAhora(cronTabLine)
  (tabla) cronTabLine: tabla que representa un evento
  Comprueba si el instante que representa el evento es en este momento --]]
function esAhora(cronTabLine)
  -- momento actual
  local ahora 	= os.date("*t") -- tabla con los valores de tiempo
  local min		= ahora.min		-- minuto
  local hour	= ahora.hour	-- hora
  local day		= ahora.day		-- dia del mes
  local month	= ahora.month	-- mes
  local wday	= ahora.wday	-- dia de la semana

  -- momento indicado en cronTabLine
  local cronTabMin 		= cronTabLine.min
  local cronTabHour		= cronTabLine.hour
  local cronTabDay		= cronTabLine.day
  local cronTabMonth	= cronTabLine.month
  local cronTabWday		= cronTabLine.wday

  -- ajustar anochecer y amanecer
  local amanecer = fibaro:getValue(1, 'sunriseHour')
  local anochecer = fibaro:getValue(1, 'sunsetHour')
  for key, value in pairs(cronTabMin) do
    if value == 'sS' then
      cronTabMin[key] = tonumber(string.format("%1d", anochecer:sub(4,5)))
    end
    if value == 'sR' then
      cronTabMin[key] = tonumber(string.format("%1d",amanecer:sub(4,5)))
    end
  end
  for key, value in pairs(cronTabHour) do
    if value == 'sS' then
      cronTabHour[key] = tonumber(string.format("%1d", anochecer:sub(1,2)))
    end
    if value == 'sR' then
      cronTabHour[key] = tonumber(string.format("%1d",amanecer:sub(1,2)))
    end
  end

  -- ajustar estaciones
  for key, value in pairs(cronTabDay) do
    if value ==  estacion(os.time()) then cronTabDay[key] = '*' end
  end
  for key, value in pairs(cronTabMonth) do
    if value ==  estacion(os.time()) then cronTabMonth[key] = '*' end
  end

  -- si todos los valores del momento actual son iguales a cronTabLine
  if ( inTable(cronTabMin, min)  and
       inTable(cronTabHour, hour)  and
       inTable(cronTabDay, day)  and
       inTable(cronTabMonth, month)  and
       inTable(cronTabWday, wday) ) then
    -- se considera que es el mismo instante
    return true
  end
  -- Si no son todos iguales, no es el momento indicado en cronTabLine
  return false
end

--[[Check(cronTab)
  (tabla) cronTab: tabla que contiene todos los eventos a comprobar
  inicia la comprobación y si hay algún evento que corresponde al momento
  actual, ejecuta su acción.
]]
function Check(cronTab)
  -- si no hay tabla de eventos salir
  if not cronTab then
    toolKit:log(ERROR, 'Tabla de eventos vacia')
    return cronTab
  end
  toolKit:log(INFO, 'Checking...')
  local evento = {}
  for key, value in pairs(cronTab) do
    if value.type == 'event' then
      -- convertir a cronTab
      evento = eventToCronTab(value.cronTab)
    elseif value.type == 'crontab' then
      -- cargar evento
      evento = value.cronTab
    else
     toolKit:log(ERROR, 'tipo de evento mal definido')
     fibaro:abort()
    end
    -- comprobar ejecución
    if esAhora(evento) then
      -- se ha producido el evento, ejecutar las acciones
      toolKit:log(INFO, '-- Se ha producido un evento --')
      -- para cada acción
      for aKey, aValue in pairs(value.acciones) do
        -- para cada dispositivo
        for dKey, dValue in pairs(aValue.dispositivos) do
          -- ejecutar la acción si es la función 'setGlobal'
          if ( aValue.funcion == 'setGlobal' ) then
            toolKit:log('setGlobal('..dValue..', '..aValue.argumento()..')')
            fibaro:setGlobal(dValue, aValue.argumento() )
          else -- para el resto de funciones usar 'call'
            toolKit:log(INFO, 'fibaro:call('..dValue..', '..aValue.funcion..', '
            ..aValue.argumento()..')')
            fibaro:call( dValue, aValue.funcion, aValue.argumento() )
          end
        end
      end
      toolKit:log(INFO, '-- Fin actividad del evento --')
    end
  end
  -- esperar al principio del siguiente minuto
  local delay = 60 - tonumber(os.date("*t").sec)
  setTimeout(function() Check(cronTab) end, delay*1000)
end

-- esperar al principio del siguiente minuto para ...
local delay = 60 - tonumber(os.date("*t").sec)
-- comenzar a comprobar si hay algo que hacer
toolKit:log(INFO, 'La comprobación comienza en '..delay..'s.')
setTimeout(function() Check(cronTab) end, delay*1000)
