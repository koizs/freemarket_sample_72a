class CreditCardsController < ApplicationController
  before_action :set_card, only: [:show, :destroy]
  
  def new
    card = CreditCard.where(user_id: current_user.id)
    redirect_to credit_card_path(current_user.id) if card.exists?
  end

  def pay
    Payjp.api_key = Rails.application.secrets[:PAYJP_PRIVATE_KEY]
    if params['payjp-token'].blank?
      redirect_to new_credit_card_path
    else
      customer = Payjp::Customer.create(
        card: params['payjp-token'],
        metadata: {user_id: current_user.id}
      ) 
      @card = CreditCard.new(user_id: current_user.id, costomer_id: customer.id, card_id: customer.default_card)
      if @card.save
        redirect_to credit_card_path(current_user.id)
      else
        redirect_to pay_credit_cards_path
      end
    end
  end

  def destroy
    if @card.present?
      Payjp.api_key = Rails.application.secrets[:PAYJP_PRIVATE_KEY]
      customer = Payjp::Customer.retrieve(@card.costomer_id)
      customer.delete
      @card.delete
    end
      redirect_to new_credit_card_path
  end

  def show
    if @card.blank?
      redirect_to new_credit_card_path 
    else
      Payjp.api_key = Rails.application.secrets[:PAYJP_PRIVATE_KEY]
      customer = Payjp::Customer.retrieve(@card.costomer_id)
      @default_card_information = customer.cards.retrieve(@card.card_id)
    end
  end

  private

  def set_card
    @card = CreditCard.find_by(user_id: current_user.id)
  end
end