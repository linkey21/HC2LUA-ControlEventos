--[[
%% properties
61 value
91 value
186 value
192 value
69 value
154 value
14 value

%% globals
upsStatus
nasStatus
--]]

--[[ Control de Eventos
	escena
	runTriggerab.lua
	por Manuel Pascual
------------------------------------------------------------------------------]]

--[[----- CONFIGURACION DE USUARIO -------------------------------------------]]
--[[ TABLA DE ACCIONES (actionTab)
actionTab['nombre'] = {funcion, dispositivos, argumento}
  (string)  funcion: cadena que inidica el nombre de la función fibaro a invocar
  (tabla)   dispositivos: tabla con los dispositivos a los que se aplicará
  (string)  argumento:  argumento para la función
} --]]

--[[------ FIN TABLA DE ACCIONES ---------------------------------------------]]

--[[ TABLA DE EVENTOS POR SUCESO (triggerTab)
  triggerTab {id={}, valor={''}, condicion=function(), retardo=0,
   acciones={actionTab['']} }
--]]

--[[---- FIN TABLA DE EVENTOS ------------------------------------------------]]
--[[----- FIN CONFIGURACION DE USUARIO ---------------------------------------]]
--[[----- NO CAMBIAR EL CODIGO A PARTIR DE AQUI ------------------------------]]

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

--[[esNoche(instante)
  (timestamp) instante: momento en el tiempo representado por un timestamp
  retorna si en el instante indicado será de noche --]]
function esNoche(instante)
  local miInstante = os.date("*t", instante)
  -- amanecer
  local amanecer = fibaro:getValue(1, 'sunriseHour')
  miInstante.min = tonumber(string.format("%1d", amanecer:sub(4,5)))
  miInstante.hour = tonumber(string.format("%1d", amanecer:sub(1,2)))
  local sunriseTime = os.time(miInstante)
  -- anochecer
  local anochecer = fibaro:getValue(1, 'sunsetHour')
  miInstante.min = tonumber(string.format("%1d", anochecer:sub(4,5)))
  miInstante.hour = tonumber(string.format("%1d", anochecer:sub(1,2)))
  local sunsetTime = os.time(miInstante)
  --
  if (instante >= sunsetTime) then return true
  elseif (instante >= sunriseTime) then return false
  else return true end
end

--[[esActivo(id)
  (number)  id: el id de un dispositivo
  indica si un dispositivo está activado --]]
function esActivo(id)
  if (fibaro:getValue(id, "value") ~= nill and
  tonumber(fibaro:getValue(id, "value")) > 0) then
    return true
  end
  return false
end

--[[function Check(triggerTab)
  (tabla) triggerTab: tabla que representa los disparadores de eventos
  Chequea si el evento producido dispara alguna acción --]]
function Check(triggerTab)
  -- fuente del inicio de la escena
  local fuenteInicio = fibaro:getSourceTrigger()
  local id, propiedad, valor, nombre, habitacion, descripcion
  if fuenteInicio['type'] == 'property' then
    id = fuenteInicio['deviceID']
    propiedad = fuenteInicio["propertyName"]
    valor = fibaro:getValue(id, propiedad)
    nombre = fibaro:getName(id)
    habitacion  = fibaro:getRoomNameByDeviceID(id)
    descripcion = ' en dispositivo '
  elseif fuenteInicio['type'] == 'global' then
    id = fuenteInicio["name"]
    propiedad = id
    valor = fibaro:getGlobalValue(id)
    habitacion = id
    descripcion = ''
    nombre = ''
  else
    return 'Ejecutado a mano, nada que hacer'
  end
  toolKit:log(DEBUG, propiedad..' '..valor..' '..nombre..' '..habitacion)
  for tKey, tValue in pairs(triggerTab) do
    if inTable(tValue.id, id) and inTable(tValue.valor, valor) and
    tValue.condicion() then
      toolKit:log(INFO, '-- Actividad por cambio de '..propiedad..' a '..
       valor..descripcion..nombre..' --')
      -- esperar retardo e intentar acciones
      toolKit:log(INFO, 'Retardo: '..tValue.retardo)
      fibaro:sleep(tValue.retardo*1000)
      -- para cada acción
      for aKey, aValue in pairs (tValue.acciones) do
        -- para cada dispositivo
        for dKey, dValue in pairs(aValue.dispositivos) do
          -- ejecutar acción
          fibaro:call(dValue, aValue.funcion, aValue.argumento)
          toolKit:log(INFO, 'fibaro:call('..dValue..', '..aValue.funcion..', '..
           aValue.argumento..')')
        end
      end
    end
  end
  return id..'-'..nombre..' en '..habitacion..' '..valor
end

OFF=1;ERROR=2;INFO=3;DEBUG=4  -- referencia para el log
nivelLog = INFO               -- nivel de log

toolKit:log(INFO, Check(triggerTab))
