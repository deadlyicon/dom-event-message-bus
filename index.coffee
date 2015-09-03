# require 'stdlibjs/Promise'
# require 'stdlibjs/Promise'
# require 'stdlibjs/Function#delay'


# i need something that will do transactions with a timeout
# over an async event bus system


DIDNT_RESPOND = {DIDNT_RESPOND: true}

module.exports = class DOMEventMessageBus

  constructor: ({@name, @color, @DOMNode, sendEvent, receiveEvent, @timeout}) ->
    @timeout ||= 1000 # <- shorten
    @lastMessageId = Date.now()
    @SEND_EVENT    = sendEvent
    @RECEIVE_EVENT = receiveEvent
    @DOMNode.addEventListener @RECEIVE_EVENT, (event) =>
      @receiveMessage(event.detail)

  log: (string) ->
    console.log("%c#{@name} #{string}", "color: #{@color}; font-weight: bold; ")

  dispatchEvent: (event, message) ->
    debugger unless @DOMNode.dispatchEvent(new CustomEvent(event, {detail:message}))
    this

  generateMessageUUID: ->
    "#{@name}-#{@lastMessageId++}"

  # sync
  sendMessage: (type, payload) ->
    id = @generateMessageUUID()
    message = {id, type, payload}

    response = DIDNT_RESPOND
    eventType = "messageResponse-#{id}"
    handler = (event) =>
      @DOMNode.removeEventListener(eventType,handler)
      response = event.detail
    @DOMNode.addEventListener(eventType,handler)
    @dispatchEvent(@SEND_EVENT, message)

    if response == DIDNT_RESPOND
      error = new Error('DOMEventMessageBus::NoResponseError')
      error.isDOMEventMessageBusNoResponseError = true
      error.message = message
      throw error
    return response

  receiveMessage: (message) ->
    {id, type, payload} = message
    @log("RECEIVED: #{id} #{type} #{JSON.stringify(payload)}")
    response = if message.type == 'echo'
      message.payload
    else
      @onReceiveMessage(message)
    @replyToMessage(message, response)

  replyToMessage: (message, response) ->
    {id, type, payload} = message
    @log("REPLIED:  #{id} #{JSON.stringify(response)}")
    @dispatchEvent("messageResponse-#{id}", response)

  isReady: ->
    try
      @sendMessage('echo','ready?') == 'ready?'
    catch error
      if error.isDOMEventMessageBusNoResponseError
        return false
      else
        throw error
