class UsersController < UserstampController
  def edit
    @user = User.find(params[:id])
    render(:inline  => "<%= @user.name %>")
  end

  def update
    @user = User.find(params[:id])
    @user.update_attributes(params.require(:user).permit(:name))
    render(:inline => "<%= @user.name %>")
  end
end
