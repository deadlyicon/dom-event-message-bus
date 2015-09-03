# require 'stdlibjs/Promise'
# require 'stdlibjs/Function#delay'


# i need something that will do transactions with a timeout
# over an async event bus system




module.exports = class DOMEventMessageBus

  constructor: ({@DOMNode, sendEvent, receiveEvent, @timeout}) ->
    Object.bindAll(this)
    @timeout ||= 1000 # <- shorten
    @lastMessageId = Date.now()
    @messagesPendingReceipt = {}
    @SEND_EVENT    = sendEvent
    @RECEIVE_EVENT = receiveEvent
    @DOMNode.addEventListener @RECEIVE_EVENT, (event) =>
      @receiveMessage(event.detail)

  dispatchEvent: (event, message) ->
    console.info('DISPATCH EVENT', event, message)
    debugger unless @DOMNode.dispatchEvent(new CustomEvent(event, {detail:message}))
    this


  sendMessage: (type, payload) ->
    message =
      id: @lastMessageId++
      type: type
      payload: payload

    return new Promise (resolve, reject) =>
      @messagesPendingReceipt[message.id] = resolve

      timeout = =>
        console.log("did message #{message.id} timeout?", @messagesPendingReceipt[message.id])
        return unless @messagesPendingReceipt[message.id]
        reject({error:'timeout sending message to Torflix'})

      setTimeout(@timeout, timeout)

      @dispatchEvent(@SEND_EVENT, message)



  receiveMessage: ({id, type, payload}) ->
    if type == 'messageReceipt'
      resolve = @messagesPendingReceipt[id]
      delete @messagesPendingReceipt[id]
      resolve?()


