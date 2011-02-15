# encoding: utf-8
module TransactionsHelper
  def cash(cash)
    if cash
      "al contado"
    else
      "a crédito"
    end
  end

  def total_currency(transaction)
    ntc(transaction.total_currency) unless session[:organisation][:currency_id] == transaction.currency_id
  end

  def currency_name(transaction)
    "Total #{transaction.currency_name.pluralize}" unless session[:organisation][:currency_id] == transaction.currency_id
  end

  def show_money(klass, amount)
    unless klass.currency_id == session[:organisation][:currency_id]
      "#{ klass.currency_symbol } #{ntc amount}"
    else
      ntc(amount)
    end
  end
end
