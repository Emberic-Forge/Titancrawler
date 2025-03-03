class APlayer : APlayerController
{
	UPROPERTY(Category = "Movement/Crouch")
    float crouchHalfHeight = 44.0;
    UPROPERTY(Category = "Movement/Crouch")
    float crouchTransitionDurationInSeconds = 0.5;
    UPROPERTY(Category = "Movement/Crouch")
    bool crouchToggle = false;

    UPROPERTY(Category = "Movement")
    float sprintSpeed = 1000.0;
    UPROPERTY(Category = "Movement")
    float walkSpeed = 600.0;
    UPROPERTY(Category = "Movement")
    bool sprintToggle = false;

	UPROPERTY(Category = "Input")
    UInputAction MoveAction;

    UPROPERTY(Category = "Input")
    UInputAction JumpAction;

    UPROPERTY(Category = "Input")
    UInputAction CrouchAction;

    UPROPERTY(Category = "Input")
    UInputAction SprintAction;

    UPROPERTY(Category = "Input")
    UInputAction LookAction;

    UPROPERTY(Category = "Input")
    UInputMappingContext Context;

    UEnhancedInputComponent InputComponent;
    ACharacter ControlledCharacter;
    UCapsuleComponent Collider;
    USpringArmComponent CameraBase;

    float defaultHalfHeight;
    bool isCrouching = false;
    bool isSprinting = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
	 InputComponent = UEnhancedInputComponent::Create(this);
     PushInputComponent(InputComponent);

     UEnhancedInputLocalPlayerSubsystem EnhancedInputSubsystem = UEnhancedInputLocalPlayerSubsystem::Get(this);
     EnhancedInputSubsystem.AddMappingContext(Context, 0, FModifyContextOptions());

     InputComponent.BindAction(MoveAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"OnMoveStart"));
     InputComponent.BindAction(JumpAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"OnJumpStart"));
     InputComponent.BindAction(JumpAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"OnJumpEnd"));
     InputComponent.BindAction(CrouchAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"OnCrouchStart"));
     InputComponent.BindAction(CrouchAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"OnCrouchEnd"));
     InputComponent.BindAction(SprintAction, ETriggerEvent::Started, FEnhancedInputActionHandlerDynamicSignature(this, n"OnSprintStart"));
     InputComponent.BindAction(SprintAction, ETriggerEvent::Completed, FEnhancedInputActionHandlerDynamicSignature(this, n"OnSprintEnd"));

     InputComponent.BindAction(LookAction, ETriggerEvent::Triggered, FEnhancedInputActionHandlerDynamicSignature(this, n"OnLookStart"));

     ControlledCharacter = Cast<ACharacter>(ControlledPawn);
     Collider = UCapsuleComponent::Get(ControlledCharacter);
     CameraBase = USpringArmComponent::Get(ControlledCharacter);


     defaultHalfHeight = Collider.CapsuleHalfHeight;
     
    }

    UFUNCTION()
    void OnLookStart(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
       ControlledCharacter.AddControllerYawInput(ActionValue.Axis2D.X);
       ControlledCharacter.AddControllerPitchInput(ActionValue.Axis2D.Y);
    }

    UFUNCTION()
    void OnMoveStart(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
       ControlledCharacter.AddMovementInput(ControlledCharacter.GetActorForwardVector(), ActionValue.Axis3D.Y);
       ControlledCharacter.AddMovementInput(ControlledCharacter.GetActorRightVector(), ActionValue.Axis3D.X);
    }

    UFUNCTION()
    void OnJumpStart(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        ControlledCharacter.Jump();
    }

    UFUNCTION()
    void OnJumpEnd(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        ControlledCharacter.StopJumping();
    }

    UFUNCTION()
    void OnCrouchStart(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        if (crouchToggle)
        {
            if(!isCrouching)
            {
                isCrouching = true;
            } else if (canUncrouch())
            {
                isCrouching = false;
            }

            return;
        }
        
        isCrouching = true;
    }

    UFUNCTION()
    void OnCrouchEnd(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        if (crouchToggle)
        {
            return;
        }

        isCrouching = canUncrouch() ?  false : isCrouching;
    }

    UFUNCTION()
    void OnSprintStart(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        if (sprintToggle)
        {
            isSprinting = !isSprinting;
            return;
        }

        isSprinting = true;
    }

    UFUNCTION()
    void OnSprintEnd(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        if (sprintToggle)
        {
            return;
        }

        isSprinting = false;
    }


    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        UpdateSprinting();
        UpdateCrouching(DeltaSeconds);
    }

    void UpdateSprinting()
    {
        float targetSpeed = isSprinting ? sprintSpeed : walkSpeed;
        ControlledCharacter.CharacterMovement.MaxWalkSpeed = targetSpeed;
    }

    void UpdateCrouching(float DeltaSeconds)
    {
        float targetHalfHeight = isCrouching ? crouchHalfHeight : defaultHalfHeight;
        float currentHalfHeight = Collider.CapsuleHalfHeight;
        float newHalfHeight = Math::FInterpTo(currentHalfHeight, targetHalfHeight, DeltaSeconds, 1.0 / crouchTransitionDurationInSeconds);
        Collider.SetCapsuleHalfHeight(newHalfHeight);
        CameraBase.RelativeLocation = FVector(0, 0, newHalfHeight - 10);
    }


    bool canUncrouch() {
        float startHalfHeight = isCrouching ? crouchHalfHeight : defaultHalfHeight;

        FVector startLocation = ControlledCharacter.GetActorLocation() + FVector(0, 0, startHalfHeight / 2.0);
        FVector endLocation = startLocation + FVector(0,0,100);
        FVector halfSize =  FVector(Collider.CapsuleRadius / 2.0, Collider.CapsuleRadius / 2.0, 10);
        FRotator orientation = FRotator(0,0,0);
        TArray<AActor> actorsToIgnore;
        actorsToIgnore.Add(ControlledCharacter);

        FHitResult hitResult;

        return !System::BoxTraceSingle(startLocation,endLocation, halfSize, orientation, ETraceTypeQuery::Visibility, false, actorsToIgnore, EDrawDebugTrace::ForDuration, hitResult, true);
    }
} 