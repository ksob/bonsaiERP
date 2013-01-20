# encoding: utf-8
class PaymentIncome < Payment

  # Validations
  validates_presence_of :income
  validate :valid_income_balance

  # Delegations
  delegate :total, :balance, to: :income, prefix: true, allow_nil: true

  # Creates the payment object
  def pay
    return false unless valid?

    res = true
    ActiveRecord::Base.transaction do
      res = save_income
      res = create_ledger && res
      res = create_interest && res

      unless res
        set_errors(income, ledger, int_ledger)
        raise ActiveRecord::Rollback
      end
    end

    res
  end

  def income
    Income.find_by_id(account_id)
  end

private
  def save_income
    update_income
    income.save
  end

  def update_income
    income.balance -= amount
    income.set_state_by_balance!
  end

  def create_ledger
    if amount.to_f > 0
      @ledger = build_ledger(amount: amount, operation: 'payin')
      @ledger.save
    else
      true
    end
  end

  def create_interest
    if interest.to_f > 0
      @int_ledger = build_ledger(amount: interest, operation: 'intin')
      @int_ledger.save
    else
      true
    end
  end

  def valid_income_balance
    if amount.to_f > income_balance.to_f
      self.errors[:amount] << 'Ingreso una cantidad mayor que el balance'
    end
  end

end
