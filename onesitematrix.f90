subroutine OnesiteMatrix(orbindex)
! this subroutine is construct the onesite operator matrix
	use variables
	use communicate

	implicit none
	integer :: orbindex
	! orbindex is the orbital index
	! this is the new site index maybe nleft+1 or nright-1

	! onesitemat(:,:,x)
	! x=1 means a(+)up
	! x=2 means a(+)down
	! x=3 means occpuation operator-nulcearQ
	! x=4 means a up
	! x=5 means a down
	call master_print_message("enter subroutine onesitematrix")

	onesitemat=0.0D0
	onesitemat(2,1,1)=1.0D0
	onesitemat(4,3,1)=1.0D0
	onesitemat(3,1,2)=1.0D0
	onesitemat(4,2,2)=-1.0D0
	onesitemat(1,1,3)=-nuclQ(orbindex)
	onesitemat(2,2,3)=1.0D0-nuclQ(orbindex)
	onesitemat(3,3,3)=1.0D0-nuclQ(orbindex)
	onesitemat(4,4,3)=2.0D0-nuclQ(orbindex)
	
	onesitemat(1,2,4)=1.0D0
	onesitemat(3,4,4)=1.0D0
	onesitemat(1,3,5)=1.0D0
	onesitemat(2,4,5)=-1.0D0
	
return

end subroutine OnesiteMatrix

