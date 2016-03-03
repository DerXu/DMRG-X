module checkmem_mod
    use module_sparse
    use kinds_mod
    use variables
    use communicate

    integer(kind=i4),allocatable :: noperamatbig1(:,:),noperamatsma1(:,:),noperamatbig2(:,:,:),noperamatsma2(:,:,:),&
        noperamatbig3(:,:,:),noperamatsma3(:,:,:),nHbig(:),nHsma(:),ncoeffIF(:),&
        noperamatbig1p(:,:),noperamatsma1p(:,:),nHbigp(:),nHsmap(:),ncoeffIFp(:)

    contains

!==============================================================================
!==============================================================================

subroutine check2d_master(mem,dim1,dim2,nmem0)
    implicit none
    integer,intent(in) :: dim1,dim2
    integer (kind=i4),intent(in) :: mem(dim1+1,dim2)
    integer,intent(inout) :: nmem0(dim2)
    integer :: i

    do i=1,dim2,1
        if(mem(dim1+1,i)>nmem0(i)) then
            nmem0(i)=mem(dim1+1,i)
        end if
    end do
    return
end subroutine check2d_master
    
!==============================================================================
!==============================================================================

subroutine check2d_slaver(mem,orbid,dim1,dim2,nmem0)
    USE MPI
    implicit none
    integer,intent(in) :: dim1,dim2,orbid(norbs,2)
    integer(kind=i4),intent(in) :: mem(:,:)
    integer(kind=i4),intent(inout) :: nmem0(:,:) !nmem0(norbs,dim2)
    integer(kind=i4) :: tmp(norbs,dim2)
    integer :: i,iorb,operaindex
    integer :: ierr

    tmp=0
    if(myid==0) then
        tmp(1:norbs,1:dim2)=nmem0(1:norbs,1:dim2)
        nmem0(1:norbs,1:dim2)=0
    end if

    do iorb=1,norbs,1
        if(myid==orbid(iorb,1)) then
            do i=1,dim2,1
                operaindex=orbid(iorb,2)*dim2-dim2+i
                tmp(iorb,i)=mem(dim1+1,operaindex)
            end do
        end if
    end do

    call MPI_REDUCE(tmp,nmem0,norbs*dim2,MPI_INTEGER4,MPI_MAX,0,MPI_COMM_WORLD,ierr)

    return
end subroutine check2d_slaver

!==============================================================================
!==============================================================================

subroutine check3d_slaver(mem,orbid,dim1,dim2,nmem0,char1)
    USE MPI
    implicit none 
    character(len=2),intent(in) :: char1
    integer,intent(in) :: dim1,dim2,orbid(norbs,norbs,2)
    integer(kind=i4),intent(in) :: mem(:,:)
    integer(kind=i4),intent(inout) :: nmem0(:,:,:) !nmem0(norbs,norbs,dim2)
    integer(kind=i4) :: tmp(norbs,norbs,dim2)
    integer :: i,iorb,jorb,operaindex
    integer :: ierr

    tmp=0
    if(myid==0) then
        tmp(1:norbs,1:norbs,1:dim2)=nmem0(1:norbs,1:norbs,1:dim2)
        nmem0(1:norbs,1:norbs,1:dim2)=0
    end if
    
    do iorb=1,norbs,1
    do jorb=1,iorb,1
        if(orbid(iorb,jorb,1)/=0 .and. myid==orbid(iorb,jorb,1)) then
            do i=1,dim2,1
                if(char1=="BO") then
                    operaindex=orbid(iorb,jorb,2)*dim2-dim2+i
                else if(char1=="LS") then
                    operaindex=orbid(iorb,jorb,2)-dim2+i
                else
                    write(*,*) "char1/=BO .and. char1/=LS"
                    stop
                end if
                tmp(iorb,jorb,i)=mem(dim1+1,operaindex)
            end do
        end if
    end do
    end do

    call MPI_REDUCE(tmp,nmem0,norbs*norbs*dim2,MPI_INTEGER4,MPI_MAX,0,MPI_COMM_WORLD,ierr)

    return
end subroutine check3d_slaver

!==============================================================================
!==============================================================================
subroutine checkmem
    
    implicit none
    if(myid==0) then
        call check2d_master(Hbigrowindex,4*subM,2,nHbig)
        call check2d_master(Hsmarowindex,subM,2,nHsma)
        call check2d_master(coeffIFrowindex,4*subM,C2state,ncoeffIF)
        if(logic_perturbation==1) then
            call check2d_master(Hbigrowindexp,4*subMp,2,nHbigp)
            call check2d_master(Hsmarowindexp,subMp,2,nHsmap)
            call check2d_master(coeffIFrowindexp,4*subMp,C2state,ncoeffIFp)
        end if
    end if

    call check2d_slaver(bigrowindex1,orbid1,4*subM,3,noperamatbig1)
    call check2d_slaver(smarowindex1,orbid1,subM,3,noperamatsma1)
    if(logic_perturbation==1) then
        call check2d_slaver(bigrowindex1p,orbid1,4*subMp,3,noperamatbig1)
        call check2d_slaver(smarowindex1p,orbid1,subMp,3,noperamatsma1)
    end if
    
    if(logic_bondorder/=0) then
        call  check3d_slaver(bigrowindex2,orbid2,4*subM,2,noperamatbig2,'BO')
        call  check3d_slaver(smarowindex2,orbid2,subM,2,noperamatsma2,'BO')
    endif
    if(logic_localspin==1) then
        call  check3d_slaver(bigrowindex3,orbid3,4*subM,2,noperamatbig3,'LS')
        call  check3d_slaver(smarowindex3,orbid3,subM,2,noperamatsma3,'LS')
    end if

    return
end subroutine checkmem

!==============================================================================
!==============================================================================

subroutine checkmem_output
    implicit none
    integer :: i,iorb,jorb

    if(myid==0) then
        open(unit=99,file="checkmem.out",status="replace")

        write(99,*) "bigrowindex1"
        write(99,*) "bigdim1=",bigdim1
        do i=1,norbs,1
            write(99,*) i,noperamatbig1(i,1:3)
        end do
        write(99,*) "smarowindex1"
        write(99,*) "smadim1=",smadim1
        do i=1,norbs,1
            write(99,*) i,noperamatsma1(i,1:3)
        end do
        write(99,*) "coeffIF"
        write(99,*) "coeffIFdim",coeffIFdim
        write(99,*) ncoeffIF(:)
        write(99,*) "Hbig"
        write(99,*) "Hbigdim=",Hbigdim
        write(99,*) nHbig(:)
        write(99,*) "Hsma"
        write(99,*) "Hsmadim=",Hsmadim
        write(99,*) nHsma(:)

        if(logic_perturbation==1) then
            write(99,*) "operamatbig1p"
            write(99,*) "bigdim1p=",bigdim1p
            do i=1,norbs,1
                write(99,*) noperamatbig1p(i,1:3)
            end do
            write(99,*) "smarowindex1p"
            write(99,*) "smadim1p=",smadim1p
            do i=1,norbs,1
                write(99,*) noperamatsma1p(i,1:3)
            end do
            write(99,*) "coeffIFp"
            write(99,*) "coeffIFdimp",coeffIFdimp
            write(99,*) ncoeffIFp(:)
            write(99,*) "Hbigp"
            write(99,*) "Hbigdimp=",Hbigdim
            write(99,*) nHbigp(:)
            write(99,*) "Hsmap"
            write(99,*) "Hsmadimp=",Hsmadimp
            write(99,*) nHsmap(:)
        end if
    
        if(logic_bondorder/=0) then
            write(99,*) "bondorder"
            write(99,*) "bigdim2=",bigdim2
            do iorb=1,norbs,1
            do jorb=1,iorb,1
                if(noperamatbig2(iorb,jorb,1)/=0 .or. noperamatbig2(iorb,jorb,1)/=0) then
                    write(99,*) iorb,jorb,noperamatbig2(iorb,jorb,1:2)
                end if
            end do
            end do
            write(99,*) "smadim2=",smadim2
            do iorb=1,norbs,1
            do jorb=1,iorb,1
                if(noperamatsma2(iorb,jorb,1)/=0 .or. noperamatsma2(iorb,jorb,1)/=0) then
                    write(99,*) iorb,jorb,noperamatsma2(iorb,jorb,1:2)
                end if
            end do
            end do
        end if
        
        if(logic_localspin/=0) then
            write(99,*) "localspin"
            write(99,*) "bigdim3=",bigdim3
            do iorb=1,norbs,1
            do jorb=1,iorb,1
                if(noperamatbig3(iorb,jorb,1)/=0 .or. noperamatbig3(iorb,jorb,1)/=0) then
                    write(99,*) iorb,jorb,noperamatbig3(iorb,jorb,1:2)
                end if
            end do
            end do
            write(99,*) "smadim3=",smadim3
            do iorb=1,norbs,1
            do jorb=1,iorb,1
                if(noperamatsma3(iorb,jorb,1)/=0 .or. noperamatsma3(iorb,jorb,1)/=0) then
                    write(99,*) iorb,jorb,noperamatsma3(iorb,jorb,1:2)
                end if
            end do
            end do
        end if
        
        close(99)
    end if

    return
end subroutine checkmem_output
    
!==============================================================================
!==============================================================================
subroutine Allocate_checkmem
    ! this subroutine is used to check the biggest memory used
    implicit none
    if(myid==0) then
        allocate(noperamatbig1(norbs,3))
        allocate(noperamatsma1(norbs,3))
        allocate(nHbig(2))
        allocate(nHsma(2))
        allocate(ncoeffIF(C2state))
        noperamatbig1=0
        noperamatsma1=0
        nHbig=0
        nHsma=0
        ncoeffIF=0

        if(logic_bondorder/=0) then
            allocate(noperamatbig2(norbs,norbs,2))
            allocate(noperamatsma2(norbs,norbs,2))
            noperamatbig2=0
            noperamatsma2=0
        end if
        if(logic_localspin==1) then
            allocate(noperamatbig3(norbs,norbs,2))
            allocate(noperamatsma3(norbs,norbs,2))
            noperamatbig3=0
            noperamatsma3=0
        end if
        if(logic_perturbation==1) then
            allocate(noperamatbig1p(norbs,3))
            allocate(noperamatsma1p(norbs,3))
            allocate(nHbigp(2))
            allocate(nHsmap(2))
            allocate(ncoeffIFp(C2state))
            noperamatbig1p=0
            noperamatsma1p=0
            nHbigp=0
            nHsmap=0
            ncoeffIFp=0
        end if
    end if
    return

end subroutine Allocate_checkmem
  
!==============================================================================
!==============================================================================

subroutine Deallocate_checkmem
    implicit none
    if(myid==0) then
        deallocate(noperamatbig1,noperamatsma1,nHbig,nHsma,ncoeffIF)
        if(logic_bondorder/=0) then
            deallocate(noperamatbig2,noperamatsma2)
        end if
        if(logic_localspin==1) then
            deallocate(noperamatbig3,noperamatsma3)
        end if
        if(logic_perturbation==1) then
            deallocate(noperamatbig1p,noperamatsma1p,nHbigp,nHsmap,ncoeffIFp)
        end if
    end if
    return
end subroutine Deallocate_checkmem

!==============================================================================
!==============================================================================
end module checkmem_mod
