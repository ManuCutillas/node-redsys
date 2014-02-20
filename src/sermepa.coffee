crypto = require 'crypto'

Utils = require './utils'

currency_mapping =
  'EUR': 978

class Sermepa
  constructor: (@config = {}) ->
    @form_url = "https://sis.redsys.es/sis/realizarPago"
    @form_url = "https://sis-t.redsys.es:25443/sis/realizarPago" if @config.test

  build_payload: (data) ->
    str = "" +
      data.total +
      data.order +
      @config.merchant.code +
      data.currency

    str += data.transaction_type if data.transaction_type and data.transaction_type isnt 0
    str += @config.urls.online if @config.urls.online

    str += @config.merchant.secret

    str

  sign: (data) =>
    shasum = crypto.createHash 'sha1'
    shasum.update @build_payload data
    shasum.digest 'hex'

  convert_currency: (currency) ->
    currency_mapping[currency]

  normalize: (data) ->
    if Math.floor(data.total) isnt data.total
      data.total *= 100

    data.currency = @convert_currency(data.currency)

    return {
      total: Utils.formatNumber data.total, 12
      currency: Utils.formatNumber data.currency, 4
      order: Utils.format data.order, 4, 12
      description: Utils.format data.description, 125
      titular: Utils.format @config.merchant.titular, 60
      merchant_code: Utils.formatNumber @config.merchant.code, 9
      merchant_url: Utils.format @config.urls.online, 250
      merchant_url_ok: Utils.format @config.urls.ok, 250
      merchant_url_ko: Utils.format @config.urls.ko, 250
      merchant_name: Utils.format @config.merchant.name, 25
      language: Utils.formatNumber @config.language, 3
      signature: Utils.format @sign(data), 40
      terminal: Utils.formatNumber 1, 3
      data: Utils.format data.data, 1024
      transaction_type: 0
      authorization_code: Utils.formatNumber data.authorization_code, 6
    }


  create_payment: (order_data) =>
    sermepa_data = @normalize(order_data)

    return {
      URL: @form_url
      Ds_Merchant_Amount: sermepa_data.total
      Ds_Merchant_Currency: sermepa_data.currency
      Ds_Merchant_Order: sermepa_data.order
      Ds_Merchant_ProductDescription: sermepa_data.description
      Ds_Merchant_Titular: sermepa_data.titular
      Ds_Merchant_MerchantCode: sermepa_data.merchant_code
      Ds_Merchant_MerchantURL: sermepa_data.merchant_url
      Ds_Merchant_UrlOK: sermepa_data.merchant_url_ok
      Ds_Merchant_UrlKO: sermepa_data.merchant_url_ko
      Ds_Merchant_MerchantName: sermepa_data.merchant_name
      Ds_Merchant_ConsumerLanguage: sermepa_data.language
      Ds_Merchant_MerchantSignature: sermepa_data.signature
      Ds_Merchant_Terminal: sermepa_data.terminal
      Ds_Merchant_MerchantData: sermepa_data.data
      Ds_Merchant_TransactionType: sermepa_data.transaction_type
      Ds_Merchant_AuthorisationCode: sermepa_data.authorization_code
    }

module.exports =
  Sermepa: Sermepa