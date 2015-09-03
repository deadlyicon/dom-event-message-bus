# require 'stdlibjs/Promise'
# require 'stdlibjs/Promise'
# require 'stdlibjs/Function#delay'


# i need something that will do transactions with a timeout
# over an async event bus system




module.exports = class DOMEventMessageBus

  constructor: ({@name, @DOMNode, sendEvent, receiveEvent, @timeout}) ->
    @timeout ||= 1000 # <- shorten
    @lastMessageId = Date.now()
    @messagesPendingReceipt = {}
    @SEND_EVENT    = sendEvent
    @RECEIVE_EVENT = receiveEvent
    @DOMNode.addEventListener @RECEIVE_EVENT, (event) =>
      @receiveMessage(event.detail)

  log: (string) ->
    console.log("%c#{@name} #{string}", 'color: purple')

  dispatchEvent: (event, message) ->
    debugger unless @DOMNode.dispatchEvent(new CustomEvent(event, {detail:message}))
    this

  generateMessageUUID: ->
    "#{@name}-#{@lastMessageId++}"

  _sendMessage: (type, payload) ->
    message =
      id: @generateMessageUUID()
      type: type
      payload: payload
    @dispatchEvent(@SEND_EVENT, message)
    message.id

  sendMessage: (type, payload) ->
    return new Promise (resolve, reject) =>
      @log('A')
      id = @_sendMessage(type, payload)
      @log('B')

      timeout = =>
        @log("did message #{id} timeout?", @messagesPendingReceipt[id])
        return unless @messagesPendingReceipt[id]
        console.log('MESSAGE PROMISE BEING REJECTED')
        reject({error:'timeout sending message to Torflix'})

      timeoutId = setTimeout(@timeout, timeout)

      @messagesPendingReceipt[id] = (response) ->
        console.log('MESSAGE PROMISE BEING RESOLVED')
        clearTimeout(timeoutId)
        resolve(response)
      @log("PENDING CALLBACL #{id} of #{Object.keys(@messagesPendingReceipt)}")

      @log("SENT:    #{type} #{id} #{JSON.stringify(payload)}")

  receiveMessage: (message) ->
    {id, type, payload} = message
    @log("RECEIVED: #{type} #{id} #{JSON.stringify(payload)}")
    if message.type == 'messageReceipt'
      id = message.payload
      resolve = @messagesPendingReceipt[id]
      @log("resolving messsage #{id} of #{Object.keys(@messagesPendingReceipt)}")
      delete @messagesPendingReceipt[id]
      resolve?()
    else
      @sendMessageReceipt(message)
      @onReceiveMessage(message)


  sendMessageReceipt: (message) ->
    @_sendMessage 'messageReceipt', message.id
