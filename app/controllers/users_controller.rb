# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
class UsersController < ApplicationController
  respond_to :html, :xml, :json

  def new
    @user = User.new
    respond_with(@user)
  end

  def create
    @user = User.new(params[:user])
    flash[:error] = t("flash.error") unless @user.save
    respond_with(@user)
  end

  def show
    @user = User.find(params[:id])
    respond_with(@user)
  end

  # GET /users/add_user
  def add_user
    @user = User.new
  end

  # POST /users/create_user
  def create_user
    @user = User.new(params[:user])
    
    @user.valid?
    render :action => 'add_user'
  end

  # GET /users/:id/edit_user
  def edit_user
  end

  # PUT /users/:id/update_user
  def update_user
  end
end
