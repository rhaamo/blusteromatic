class NodesController < ApplicationController
  before_filter :authenticate_user!

  # DELETE /nodes/1
  # DELETE /nodes/1.json
  def destroy
    @node = Node.find(params[:id])
    @node.destroy

    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { head :no_content }
    end
  end

  def activate
    @node = Node.find(params[:node_id])
    @node.validated = 1
    @node.save
    redirect_to root_url, :notice => "Node #{@node.name} successfully validated"
  end

  def deactivate
  end

  def pause
    redirect_to root_url, :notice => "Not currently implemented"
  end
end
